import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String? bookingId;
  final String? parkingId;
  final String type;
  final int? rating;
  final String comment;
  final String status;
  final bool refunded;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.bookingId,
    this.parkingId,
    required this.type,
    this.rating,
    required this.comment,
    this.status = 'pending',
    this.refunded = false,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      bookingId: map['bookingId'],
      parkingId: map['parkingId'],
      type: map['type'] ?? 'review',
      rating: map['rating'],
      comment: map['comment'] ?? '',
      status: map['status'] ?? 'pending',
      refunded: map['refunded'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'bookingId': bookingId,
      'parkingId': parkingId,
      'type': type,
      'rating': rating,
      'comment': comment,
      'status': status,
      'refunded': refunded,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
