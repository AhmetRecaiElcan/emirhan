import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Koleksiyon referansı
  CollectionReference get _productsRef => _firestore.collection('products');

  Future<String> addProduct(ProductModel product) async {
    await _productsRef.doc(product.id).set(product.toMap());
    return product.id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _productsRef.doc(product.id).update(product.toMap(isUpdate: true));
  }

  // Tüm ürünleri getir (havuz) - stream
  Stream<List<ProductModel>> getProducts() {
    return _productsRef.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) =>
              ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Kullanıcının ürünlerini getir - stream
  // Not: sıralama istemci tarafında (composite index beklemeden çalışır)
  Stream<List<ProductModel>> getUserProducts(String userId) {
    return _productsRef
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) =>
              ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      products.sort((a, b) {
        if (a.isLowStock != b.isLowStock) {
          return a.isLowStock ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return products;
    });
  }

  // Ürün miktarını güncelle
  Future<void> updateProductQuantity(String productId, double newQuantity) async {
    await _productsRef.doc(productId).update({'quantity': newQuantity});
  }

  // Ürün sil
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  // Tek ürün getir
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Ürün stream (tek ürün)
  Stream<ProductModel?> getProductStream(String productId) {
    return _productsRef.doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }
}
