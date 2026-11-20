import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// PIN'i Firebase şifresine çevirir (kayıt ve girişte ortak kullanılır).
  static String pinToPassword(String pin) => 'depo_pin_${pin}_secure';

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<List<UserModel>> getProfiles() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      debugPrint('📋 Firestore users koleksiyonu: ${snapshot.docs.length} kullanıcı bulundu');
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
      users.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return users;
    }).handleError((error) {
      debugPrint('❌ Firestore users okuma hatası: $error');
      return <UserModel>[];
    });
  }

  Future<int> getProfileCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final count = await getProfileCount();
      if (count >= AppConstants.maxProfiles) {
        return 'En fazla ${AppConstants.maxProfiles} profil oluşturulabilir.';
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);

        final userModel = UserModel(
          uid: result.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap());

        await result.user!.sendEmailVerification();
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // E-posta Firebase Auth'ta kayıtlı: profili silinmiş bir hesap ise
        // aynı PIN ile yeniden oluşturmayı dene.
        return _recreateDeletedProfile(
          email: email,
          password: password,
          displayName: displayName,
        );
      }
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  /// Profili Firestore'dan silinmiş ama Firebase Auth kaydı (e-posta) kalmış
  /// kullanıcılar için: e-posta + PIN doğruysa hesabı ve profili yeniden kurar.
  Future<String?> _recreateDeletedProfile({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) {
        return _getErrorMessage('email-already-in-use');
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        // Profil hâlâ kayıtlı: e-postayı gerçekten başka bir profil kullanıyor,
        // açılan oturumu geri kapat.
        await _auth.signOut();
        return _getErrorMessage('email-already-in-use');
      }

      // Profil kaydı silinmiş -> aynı hesapla (aynı uid ile) yeniden oluştur
      await user.updateDisplayName(displayName);
      await docRef.set(
        UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        ).toMap(),
      );
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        if (!await _hasProfileWithEmail(email)) {
          return 'Bu e-posta silinmiş bir profile ait. '
              'Kayıt olurken daha önce kullandığınız PIN kodunu girin.';
        }
        return _getErrorMessage('email-already-in-use');
      }
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  /// Verilen e-posta ile kayıtlı bir profil belgesi var mı?
  Future<bool> _hasProfileWithEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ E-posta sorgusu hatası: $e');
      // Emin değilsek e-postayı kullanımda say
      return true;
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null && !result.user!.emailVerified) {
        return 'EMAIL_NOT_VERIFIED';
      }

      await _ensureUserDoc();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: $e';
    }
  }

  Future<void> _ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = _firestore.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Kullanıcı',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Mevcut profili ve Firestore kaydını sil
  Future<void> deleteCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Firestore 'users' koleksiyonundan profili sil
    await _firestore.collection('users').doc(uid).delete();

    // 2. Firebase Authentication'dan kullanıcıyı sil
    try {
      await user.delete();
    } catch (e) {
      debugPrint('FirebaseAuth delete uyarısı (signOut yapılıyor): $e');
      await _auth.signOut();
    }
    notifyListeners();
  }

  /// Profili hem Firestore'dan hem de Firebase Authentication'dan siler.
  ///
  /// E-postanın ileride yeniden kullanılabilmesi için Auth hesabının da
  /// silinmesi şarttır; bunun için o profilin PIN'i ile giriş yapılır.
  /// [pin] null verilirse sadece Firestore kaydı silinir ve e-posta
  /// Firebase'de rezerve kalır (önerilmez).
  ///
  /// Başarılıysa null, hata durumunda gösterilecek mesaj döner ve
  /// hiçbir kayıt silinmemiş olur.
  Future<String?> deleteProfileByUid(
    String uid, {
    required String email,
    String? pin,
  }) async {
    if (pin != null) {
      try {
        // 1. Silinecek profilin Auth hesabına giriş yap
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: pinToPassword(pin),
        );
        // 2. Auth hesabını sil -> e-posta serbest kalır
        await credential.user?.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return 'PIN hatalı. Profil silinmedi.';
        }
        // Auth hesabı zaten yoksa devam edip sadece kaydı temizleriz
        if (e.code != 'user-not-found') {
          return _getErrorMessage(e.code);
        }
      }
    }

    // 3. Firestore kaydını sil
    await _firestore.collection('users').doc(uid).delete();
    notifyListeners();
    return null;
  }

  Future<String?> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return null;
    } catch (e) {
      return 'Doğrulama maili gönderilemedi: $e';
    }
  }

  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    notifyListeners();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<String> getUserDisplayName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['displayName'] ?? 'Bilinmeyen';
      }
      return 'Bilinmeyen';
    } catch (e) {
      return 'Bilinmeyen';
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen bekleyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
