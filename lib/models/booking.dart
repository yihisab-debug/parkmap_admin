import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String parkingId;
  final String parkingName;
  final String userId;
  final String userName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int spotNumber;
  final int totalPrice;
  final String status;

  Booking({
    required this.id,
    required this.parkingId,
    required this.parkingName,
    required this.userId,
    required this.userName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.spotNumber,
    required this.totalPrice,
    this.status = 'active',
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      parkingId: map['parkingId'] ?? '',
      parkingName: map['parkingName'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      spotNumber: (map['spotNumber'] ?? 0) as int,
      totalPrice: (map['totalPrice'] ?? 0) as int,
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parkingId': parkingId,
      'parkingName': parkingName,
      'userId': userId,
      'userName': userName,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'spotNumber': spotNumber,
      'totalPrice': totalPrice,
      'status': status,
    };
  }

  DateTime get endDateTime {
    final parts = endTime.split(':');
    return DateTime(date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime get startDateTime {
    final parts = startTime.split(':');
    return DateTime(date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }
}
