import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../models/fine.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ParkingLot>> watchParkingLots() {
    return _db.collection('parkingLots').snapshots().map((snap) => snap.docs
        .map((d) => ParkingLot.fromMap(d.id, d.data()))
        .toList());
  }

  Future<void> addParkingLot(ParkingLot lot) async {
    await _db.collection('parkingLots').add(lot.toMap());
  }

  Future<void> updateParkingLot(String id, ParkingLot lot) async {
    await _db.collection('parkingLots').doc(id).update(lot.toMap());
  }

  Future<void> deleteParkingLot(String id) async {
    await _db.collection('parkingLots').doc(id).delete();
  }

  Stream<List<Booking>> watchTodayBookings(String parkingId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _db
        .collection('bookings')
        .where('parkingId', isEqualTo: parkingId)
        .where('status', isEqualTo: 'active')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Booking>> watchAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('date', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Review>> watchReviews() {
    return _db
        .collection('reviews')
        .where('type', isEqualTo: 'review')
        .snapshots()
        .map((snap) {
      final reviews =
          snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  Stream<List<Review>> watchComplaints() {
    return _db
        .collection('reviews')
        .where('type', isEqualTo: 'complaint')
        .snapshots()
        .map((snap) {
      final reviews =
          snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  Future<void> acceptComplaint(Review complaint) async {
    final reviewRef = _db.collection('reviews').doc(complaint.id);

    await _db.runTransaction((tx) async {
      tx.update(reviewRef, {'status': 'accepted', 'refunded': complaint.bookingId != null});

      if (complaint.bookingId != null) {
        final bookingRef = _db.collection('bookings').doc(complaint.bookingId);
        final bookingSnap = await tx.get(bookingRef);
        if (bookingSnap.exists) {
          final data = bookingSnap.data()!;
          final alreadyRefunded = data['status'] == 'refunded';
          if (!alreadyRefunded) {
            final amount = (data['totalPrice'] ?? 0) as int;
            final userId = data['userId'] as String;
            final userRef = _db.collection('users').doc(userId);
            final userSnap = await tx.get(userRef);
            final balance = (userSnap.data()?['balance'] ?? 0) as int;

            tx.update(userRef, {'balance': balance + amount});
            tx.update(bookingRef, {'status': 'refunded'});
          }
        }
      }
    });
  }

  Future<void> rejectComplaint(String complaintId) async {
    await _db.collection('reviews').doc(complaintId).update({
      'status': 'rejected',
      'refunded': false,
    });
  }

  Future<void> fineUser({
    required String userId,
    required String userName,
    required int amount,
    required String reason,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    final fineRef = _db.collection('fines').doc();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final balance = (userSnap.data()?['balance'] ?? 0) as int;
      tx.update(userRef, {'balance': balance - amount});
      tx.set(fineRef, Fine(
        id: fineRef.id,
        userId: userId,
        userName: userName,
        amount: amount,
        reason: reason,
        createdAt: DateTime.now(),
      ).toMap());
    });
  }

  Stream<List<Fine>> watchFines() {
    return _db
        .collection('fines')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Fine.fromMap(d.id, d.data())).toList());
  }
}
