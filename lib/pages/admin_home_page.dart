import 'package:flutter/material.dart';
import '../models/parking_spot.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'add_edit_parking_page.dart';
import 'spots_status_page.dart';
import 'reviews_complaints_page.dart';
import 'fines_page.dart';
import 'clients_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Клиенты',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.reviews_outlined),
            tooltip: 'Отзывы и жалобы',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewsComplaintsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.gavel),
            tooltip: 'Штрафы',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinesPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Добавить парковку'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditParkingPage()),
        ),
      ),
      body: StreamBuilder<List<ParkingLot>>(
        stream: firestoreService.watchParkingLots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить парковки'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          final lots = snapshot.data ?? [];
          if (lots.isEmpty) {
            return const Center(child: Text('Парковки не найдены. Добавьте первую.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: lots.length,
            itemBuilder: (context, index) {
              final lot = lots[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SpotsStatusPage(lot: lot)),
                  ),
                  leading: const Icon(Icons.local_parking, color: Colors.blue),
                  title: Text(lot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${lot.address}\n${lot.totalSpots} мест · ${lot.pricePerHour} ₸ / час'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddEditParkingPage(existingLot: lot)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Удалить парковку?'),
                              content: Text('Парковка "${lot.name}" будет удалена без возможности восстановления.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Отмена')),
                                TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Удалить')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await firestoreService.deleteParkingLot(lot.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
