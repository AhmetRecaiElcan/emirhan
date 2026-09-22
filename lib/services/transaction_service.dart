import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _transactionsRef => _firestore.collection('transactions');

  // Yeni işlem ekle
  Future<String> addTransaction(TransactionModel transaction) async {
    final docRef = await _transactionsRef.add(transaction.toMap());
    return docRef.id;
  }

  // Tüm işlemleri getir - stream
  Stream<List<TransactionModel>> getAllTransactions() {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Ürüne ait işlemleri getir - stream
  Stream<List<TransactionModel>> getProductTransactions(String productId) {
    return _transactionsRef
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Kullanıcının işlemlerini getir
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _transactionsRef
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Tek bir işlemi sil
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsRef.doc(transactionId).delete();
  }

  // Tüm işlemleri temizle (toplu silme)
  Future<void> clearAllTransactions() async {
    final snapshot = await _transactionsRef.get();
    final docs = snapshot.docs;
    if (docs.isEmpty) return;

    // Firestore batch maksimum 500 işlem destekler
    for (var i = 0; i < docs.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < docs.length) ? i + 500 : docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
  }
}
