import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  static const String typeOut = 'out';
  static const String typeIn = 'in';

  final String id;
  final String productId;
  final String productName;
  final String fromUserId;
  final String fromUserName;
  final String toUserName;
  final double quantity;
  final String unit;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String type;

  TransactionModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserName,
    required this.quantity,
    required this.unit,
    required this.transactionDate,
    required this.createdAt,
    this.type = typeOut,
  });

  bool get isIncrease => type == typeIn;

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TransactionModel(
      id: docId,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toUserName: map['toUserName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      transactionDate:
          (map['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? typeOut,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'quantity': quantity,
      'unit': unit,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
    };
  }
}
