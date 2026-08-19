import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';

class MapPickResult {
  final LatLng point;
  final String? address;
  const MapPickResult({required this.point, this.address});
}

class MapPickerPage extends StatefulWidget {
  final LatLng initialCenter;
  final LatLng? initialMarker;

  const MapPickerPage({
    super.key,
    this.initialCenter = const LatLng(43.2389, 76.8897),
    this.initialMarker,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _geocodingService = GeocodingService();
  final _searchController = TextEditingController();
  final _mapController = MapController();

  LatLng? _selectedPoint;
  String? _resolvedAddress;
  bool _isSearching = false;
  bool _isResolvingAddress = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialMarker;
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _resolvedAddress = null;
      _isResolvingAddress = true;
    });

    final address = await _geocodingService.reverse(point);

    if (mounted) {
      setState(() {
        _resolvedAddress = address;
        _isResolvingAddress = false;
      });
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final result = await _geocodingService.forward(query);

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (result == null) {
      setState(() => _searchError = 'Адрес не найден, попробуйте иначе сформулировать');
      return;
    }

    _mapController.move(result.point, 16);
    setState(() {
      _selectedPoint = result.point;
      _resolvedAddress = result.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите точку на карте')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialMarker ?? widget.initialCenter,
              initialZoom: 14,
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.parkmap_admin',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Найти адрес...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchAddress(),
                      ),
                    ),
                    _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchAddress,
                          ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 12,
            right: 12,
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _selectedPoint == null
                          ? const Text(
                              'Нажмите на карту или найдите адрес выше',
                              style: TextStyle(fontSize: 13),
                            )
                          : Text(
                              _isResolvingAddress
                                  ? 'Определяю адрес...'
                                  : (_resolvedAddress ??
                                      'Широта: ${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                                          'Долгота: ${_selectedPoint!.longitude.toStringAsFixed(6)}'),
                              style: const TextStyle(fontSize: 13),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_searchError != null)
            Positioned(
              bottom: 160,
              left: 12,
              right: 12,
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_searchError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedPoint == null
            ? null
            : () => Navigator.pop(
                  context,
                  MapPickResult(point: _selectedPoint!, address: _resolvedAddress),
                ),
        icon: const Icon(Icons.check),
        label: const Text('Подтвердить точку'),
      ),
    );
  }
}
