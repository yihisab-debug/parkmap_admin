import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/fine.dart';
import '../services/firestore_service.dart';

class FinesPage extends StatelessWidget {
  const FinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Штрафы')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Оштрафовать клиента'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _FineClientSheet(firestoreService: firestoreService),
        ),
      ),
      body: StreamBuilder<List<Fine>>(
        stream: firestoreService.watchFines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final fines = snapshot.data ?? [];
          if (fines.isEmpty) {
            return const Center(child: Text('Штрафов пока не выписано'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: fines.length,
            itemBuilder: (context, index) {
              final f = fines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.deepOrange),
                  title: Text('${f.userName} — ${f.amount} ₸'),
                  subtitle: Text(
                      '${f.reason}\n${DateFormat('d MMM yyyy, HH:mm', 'ru').format(f.createdAt)}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FineClientSheet extends StatefulWidget {
  final FirestoreService firestoreService;
  const _FineClientSheet({required this.firestoreService});

  @override
  State<_FineClientSheet> createState() => _FineClientSheetState();
}

class _FineClientSheetState extends State<_FineClientSheet> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  Booking? _selectedBooking;
  bool _isSaving = false;

  Future<void> _submit() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (_selectedBooking == null || amount == null || amount <= 0 ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните все поля корректно')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.firestoreService.fineUser(
        userId: _selectedBooking!.userId,
        userName: _selectedBooking!.userName,
        amount: amount,
        reason: _reasonController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Оштрафовать клиента',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<Booking>>(
            stream: widget.firestoreService.watchAllBookings(),
            builder: (context, snapshot) {
              final bookings = snapshot.data ?? [];
              if (bookings.isEmpty) {
                return const Text('Нет бронирований, чтобы выбрать клиента');
              }
              return DropdownButtonFormField<Booking>(
                decoration: const InputDecoration(labelText: 'Клиент (по бронированию)'),
                value: _selectedBooking,
                items: bookings
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(
                              '${b.userName} — ${b.parkingName}, место №${b.spotNumber}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (b) => setState(() => _selectedBooking = b),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Сумма штрафа (₸)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Причина штрафа'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Оштрафовать'),
            ),
          ),
        ],
      ),
    );
  }
}
