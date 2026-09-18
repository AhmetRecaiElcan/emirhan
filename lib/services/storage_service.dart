import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Ürün fotoğrafı yükle (Web ve Mobil tam uyumlu putData)
  Future<String> uploadProductImage(Uint8List bytes, String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId/image.jpg');

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Fotoğraf yüklenemedi: $e');
    }
  }

  // Ürün fotoğrafı sil
  Future<void> deleteProductImage(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId/image.jpg');
      await ref.delete();
    } catch (e) {
      // Dosya yoksa hata vermesin
    }
  }
}
