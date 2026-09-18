import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String depot;
  final String imageUrl;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final double minQuantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.depot,
    required this.imageUrl,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.minQuantity = 0,
  });

  bool get isLowStock => quantity <= minQuantity;

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'Adet',
      depot: map['depot'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minQuantity: (map['minQuantity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap({bool isUpdate = false}) {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'depot': depot,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'minQuantity': minQuantity,
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? depot,
    String? imageUrl,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    double? minQuantity,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      depot: depot ?? this.depot,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      minQuantity: minQuantity ?? this.minQuantity,
    );
  }
}
