import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// ผลลัพธ์ geocoding หนึ่งรายการ
class GeoResult {
  final String displayName;
  final LatLng latLng;
  const GeoResult({required this.displayName, required this.latLng});
}

/// แปลงที่อยู่ ↔ พิกัด ผ่าน Nominatim (OpenStreetMap) — ฟรี ไม่ต้องใช้ API key
///
/// หมายเหตุ: Nominatim usage policy บังคับให้ส่ง User-Agent ที่ระบุแอปได้
/// และจำกัดความถี่ ~1 req/วินาที (พอสำหรับการค้นหาตามผู้ใช้กด)
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'delivery_app_flutter/1.0'};

  /// ค้นหาที่อยู่ → พิกัด (forward geocoding)
  Future<List<GeoResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'limit': '5',
      'accept-language': 'th',
    });

    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw GeocodingException('ค้นหาที่อยู่ไม่สำเร็จ (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data
        .map((e) => GeoResult(
              displayName: (e['display_name'] ?? '') as String,
              latLng: LatLng(
                double.parse(e['lat'] as String),
                double.parse(e['lon'] as String),
              ),
            ))
        .toList();
  }

  /// พิกัด → ข้อความที่อยู่ (reverse geocoding) สำหรับเติมให้ตอนจิ้มแผนที่
  Future<String> reverse(LatLng point) async {
    final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
      'lat': '${point.latitude}',
      'lon': '${point.longitude}',
      'format': 'jsonv2',
      'accept-language': 'th',
    });

    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw GeocodingException('แปลงพิกัดเป็นที่อยู่ไม่สำเร็จ');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (data['display_name'] ?? '') as String;
  }
}

class GeocodingException implements Exception {
  final String message;
  GeocodingException(this.message);
  @override
  String toString() => message;
}
