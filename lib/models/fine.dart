import 'package:cloud_firestore/cloud_firestore.dart';

class Fine {
  final String id;
  final String userId;
  final String userName;
  final int amount;
  final String reason;
  final DateTime createdAt;

  Fine({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  factory Fine.fromMap(String id, Map<String, dynamic> map) {
    return Fine(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0) as int,
      reason: map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
