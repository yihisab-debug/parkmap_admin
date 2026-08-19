import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const String _apiKey = 'f08d1c31e67f6131335f8bcda96ab97b';
  static const String _baseUrl = 'http://api.positionstack.com/v1';

  Future<GeocodeResult?> forward(String query) async {
    if (query.trim().isEmpty) return null;
    final uri = Uri.parse('$_baseUrl/forward').replace(queryParameters: {
      'access_key': _apiKey,
      'query': query.trim(),
      'limit': '1',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List?;
      if (data == null || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num?)?.toDouble();
      final lng = (first['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return GeocodeResult(
        point: LatLng(lat, lng),
        label: (first['label'] as String?) ?? query,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> reverse(LatLng point) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
      'access_key': _apiKey,
      'query': '${point.latitude},${point.longitude}',
      'limit': '1',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List?;
      if (data == null || data.isEmpty) return null;

      final first = data.first as Map<String, dynamic>;
      return first['label'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class GeocodeResult {
  final LatLng point;
  final String label;
  const GeocodeResult({required this.point, required this.label});
}
