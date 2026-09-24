import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Beklenmeyen bir hata oluştu: $e';
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

  // Belirli bir UID'ye ait profili Firestore'dan sil
  Future<void> deleteProfileByUid(String uid) async {
    // 1. Firestore'dan kullanıcı belgesini sil
    await _firestore.collection('users').doc(uid).delete();

    // 2. Eğer o kullanıcı oturum açmışsa oturumu kapat veya auth'tan sil
    if (_auth.currentUser?.uid == uid) {
      try {
        await _auth.currentUser?.delete();
      } catch (e) {
        await _auth.signOut();
      }
    }
    notifyListeners();
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
