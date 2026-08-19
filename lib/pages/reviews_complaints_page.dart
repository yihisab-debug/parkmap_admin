import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';
import '../services/firestore_service.dart';

class ReviewsComplaintsPage extends StatefulWidget {
  const ReviewsComplaintsPage({super.key});

  @override
  State<ReviewsComplaintsPage> createState() => _ReviewsComplaintsPageState();
}

class _ReviewsComplaintsPageState extends State<ReviewsComplaintsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept(Review complaint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Принять жалобу?'),
        content: const Text(
            'Деньги за соответствующее бронирование будут возвращены клиенту на баланс.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Принять')),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestoreService.acceptComplaint(complaint);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Жалоба принята, деньги возвращены')));
      }
    }
  }

  Future<void> _handleReject(Review complaint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отклонить жалобу?'),
        content: const Text('Деньги клиенту не будут возвращены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Отклонить')),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestoreService.rejectComplaint(complaint.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Жалоба отклонена')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы и жалобы'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Отзывы'),
            Tab(text: 'Жалобы'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReviewsList(firestoreService: _firestoreService),
          _ComplaintsList(
            firestoreService: _firestoreService,
            onAccept: _handleAccept,
            onReject: _handleReject,
          ),
        ],
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final FirestoreService firestoreService;
  const _ReviewsList({required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: firestoreService.watchReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(child: Text('Отзывов пока нет'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final r = reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(r.userName),
                subtitle: Text(
                    '${r.comment}\n${DateFormat('d MMM yyyy, HH:mm', 'ru').format(r.createdAt)}'),
                isThreeLine: true,
                trailing: Text('${r.rating ?? '-'} ★'),
              ),
            );
          },
        );
      },
    );
  }
}

class _ComplaintsList extends StatelessWidget {
  final FirestoreService firestoreService;
  final void Function(Review) onAccept;
  final void Function(Review) onReject;

  const _ComplaintsList({
    required this.firestoreService,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: firestoreService.watchComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final complaints = snapshot.data ?? [];
        if (complaints.isEmpty) {
          return const Center(child: Text('Жалоб пока нет'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final c = complaints[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(c.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        _StatusChip(status: c.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c.comment),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM yyyy, HH:mm', 'ru').format(c.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (c.status == 'pending') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => onAccept(c),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Принять и вернуть деньги'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => onReject(c),
                            child: const Text('Отклонить'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;
    switch (status) {
      case 'pending':
        label = 'На рассмотрении';
        color = Colors.orange;
        break;
      case 'accepted':
        label = 'Принята';
        color = Colors.green;
        break;
      default:
        label = 'Отклонена';
        color = Colors.red;
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
