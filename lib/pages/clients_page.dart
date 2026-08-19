import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/firestore_service.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _firestoreService = FirestoreService();
  bool _onlyActive = true;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Клиенты')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Найти клиента или парковку...',
                filled: true,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Только активные сейчас'),
                const Spacer(),
                Switch(
                  value: _onlyActive,
                  onChanged: (v) => setState(() => _onlyActive = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _firestoreService.watchAllBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Не удалось загрузить бронирования'));
                }

                final now = DateTime.now();
                var bookings = snapshot.data ?? [];

                if (_onlyActive) {
                  bookings = bookings
                      .where((b) =>
                          b.status == 'active' &&
                          now.isAfter(b.startDateTime) &&
                          now.isBefore(b.endDateTime))
                      .toList();
                }

                if (_query.isNotEmpty) {
                  bookings = bookings
                      .where((b) =>
                          b.userName.toLowerCase().contains(_query) ||
                          b.parkingName.toLowerCase().contains(_query))
                      .toList();
                }

                if (bookings.isEmpty) {
                  return Center(
                    child: Text(_onlyActive
                        ? 'Сейчас нет клиентов на парковках'
                        : 'Бронирований не найдено'),
                  );
                }

                final byClient = <String, List<Booking>>{};
                for (final b in bookings) {
                  byClient.putIfAbsent(b.userId, () => []).add(b);
                }
                final clientIds = byClient.keys.toList()
                  ..sort((a, b) =>
                      byClient[a]!.first.userName.compareTo(byClient[b]!.first.userName));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: clientIds.length,
                  itemBuilder: (context, index) {
                    final clientBookings = byClient[clientIds[index]]!;
                    clientBookings.sort((a, b) => b.date.compareTo(a.date));
                    final clientName = clientBookings.first.userName;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${clientBookings.length} '
                            '${_pluralBookings(clientBookings.length)}'),
                        children: clientBookings
                            .map((b) => _BookingTile(booking: b, now: now))
                            .toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _pluralBookings(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'бронирование';
    if ([2, 3, 4].contains(mod10) && !(mod100 >= 12 && mod100 <= 14)) {
      return 'бронирования';
    }
    return 'бронирований';
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final DateTime now;
  const _BookingTile({required this.booking, required this.now});

  @override
  Widget build(BuildContext context) {
    final isCurrentlyActive = booking.status == 'active' &&
        now.isAfter(booking.startDateTime) &&
        now.isBefore(booking.endDateTime);

    return ListTile(
      dense: true,
      leading: Icon(
        Icons.local_parking,
        color: isCurrentlyActive ? Colors.green : Colors.grey,
      ),
      title: Text('${booking.parkingName} — место №${booking.spotNumber}'),
      subtitle: Text(
        '${DateFormat('d MMM yyyy', 'ru').format(booking.date)}, '
        '${booking.startTime}–${booking.endTime} · ${booking.totalPrice} ₸',
      ),
      trailing: isCurrentlyActive
          ? const Chip(
              label: Text('Сейчас на месте', style: TextStyle(fontSize: 11)),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
    );
  }
}
