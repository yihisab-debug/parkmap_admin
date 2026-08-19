import 'dart:async';
import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../services/firestore_service.dart';

class SpotsStatusPage extends StatefulWidget {
  final ParkingLot lot;
  const SpotsStatusPage({super.key, required this.lot});

  @override
  State<SpotsStatusPage> createState() => _SpotsStatusPageState();
}

class _SpotsStatusPageState extends State<SpotsStatusPage> {
  final _firestoreService = FirestoreService();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return '0 мин';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h ч $m мин';
    return '$m мин';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Места — ${widget.lot.name}')),
      body: StreamBuilder<List<Booking>>(
        stream: _firestoreService.watchTodayBookings(widget.lot.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final allBookingsToday = snapshot.data ?? [];
          final currentBySpot = <int, Booking>{};
          for (final b in allBookingsToday) {
            if (now.isAfter(b.startDateTime) && now.isBefore(b.endDateTime)) {
              currentBySpot[b.spotNumber] = b;
            }
          }
          final freeCount = widget.lot.totalSpots - currentBySpot.length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.06),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(label: 'Всего мест', value: '${widget.lot.totalSpots}'),
                    _StatBox(
                        label: 'Свободно', value: '$freeCount', color: Colors.green),
                    _StatBox(
                        label: 'Занято',
                        value: '${currentBySpot.length}',
                        color: Colors.red),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: widget.lot.totalSpots,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final booking = currentBySpot[number];
                    final isOccupied = booking != null;
                    return Container(
                      decoration: BoxDecoration(
                        color: isOccupied ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOccupied ? Colors.red[400]! : Colors.green[400]!,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(number.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            isOccupied ? 'Занято' : 'Свободно',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOccupied ? Colors.red[900] : Colors.green[900],
                            ),
                          ),
                          if (isOccupied) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Осталось:\n${_formatRemaining(booking!.endDateTime.difference(now))}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
