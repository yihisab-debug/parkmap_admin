import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/parking_spot.dart';
import '../services/firestore_service.dart';
import 'map_picker_page.dart';

class AddEditParkingPage extends StatefulWidget {
  final ParkingLot? existingLot;

  const AddEditParkingPage({super.key, this.existingLot});

  @override
  State<AddEditParkingPage> createState() => _AddEditParkingPageState();
}

class _AddEditParkingPageState extends State<AddEditParkingPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _totalSpotsController;
  late final TextEditingController _priceController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  bool _isSaving = false;

  Future<void> _pickLocationOnMap() async {
    final currentLat = double.tryParse(_latController.text.trim());
    final currentLng = double.tryParse(_lngController.text.trim());
    final initialMarker = (currentLat != null && currentLng != null)
        ? LatLng(currentLat, currentLng)
        : null;

    final result = await Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initialMarker: initialMarker),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.point.latitude.toStringAsFixed(6);
        _lngController.text = result.point.longitude.toStringAsFixed(6);
        if (result.address != null && _addressController.text.trim().isEmpty) {
          _addressController.text = result.address!;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final lot = widget.existingLot;
    _nameController = TextEditingController(text: lot?.name ?? '');
    _addressController = TextEditingController(text: lot?.address ?? '');
    _totalSpotsController =
        TextEditingController(text: lot != null ? lot.totalSpots.toString() : '');
    _priceController =
        TextEditingController(text: lot != null ? lot.pricePerHour.toString() : '');
    _latController =
        TextEditingController(text: lot != null ? lot.latitude.toString() : '');
    _lngController =
        TextEditingController(text: lot != null ? lot.longitude.toString() : '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final lot = ParkingLot(
      id: widget.existingLot?.id ?? '',
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      totalSpots: int.parse(_totalSpotsController.text.trim()),
      pricePerHour: int.parse(_priceController.text.trim()),
      latitude: double.parse(_latController.text.trim()),
      longitude: double.parse(_lngController.text.trim()),
    );

    try {
      if (widget.existingLot == null) {
        await _firestoreService.addParkingLot(lot);
      } else {
        await _firestoreService.updateParkingLot(widget.existingLot!.id, lot);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingLot != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Редактировать парковку' : 'Добавить парковку')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название парковки'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите название' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Адрес'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите адрес' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalSpotsController,
              decoration: const InputDecoration(labelText: 'Количество парковочных мест'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Число должно быть больше 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Цена за час (₸)'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Цена должна быть больше 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _latController,
              decoration: const InputDecoration(labelText: 'Широта (latitude)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Введите корректное число' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lngController,
              decoration: const InputDecoration(labelText: 'Долгота (longitude)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Введите корректное число' : null,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickLocationOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Выбрать точку на карте'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Совет: координаты можно посмотреть на openstreetmap.org, кликнув правой '
              'кнопкой по нужной точке на карте.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
