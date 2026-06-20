import 'package:geolocator/geolocator.dart';

/// จัดการตำแหน่ง GPS ผ่าน geolocator
/// ใช้ทั้งตอนเลือกพิกัด (ปุ่ม "ตำแหน่งปัจจุบัน") และตอนติดตามไรเดอร์ภายหลัง
class LocationService {
  /// ขอสิทธิ์ + คืนตำแหน่งปัจจุบัน, โยน [LocationException] ถ้าทำไม่ได้
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('กรุณาเปิด GPS / Location ของเครื่อง');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
          'ถูกปฏิเสธสิทธิ์ตำแหน่งถาวร กรุณาเปิดในตั้งค่าแอป');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// stream ตำแหน่งแบบต่อเนื่อง (ใช้ในหน้าแผนที่ไรเดอร์ real-time)
  /// distanceFilter = ขยับอย่างน้อยกี่เมตรถึงจะส่ง event ใหม่ (ลดการเขียนถี่)
  Stream<Position> positionStream({int distanceFilter = 5}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        ),
      );

  /// ระยะทางเป็นเมตรระหว่าง 2 พิกัด (ใช้เช็คเงื่อนไข 20 เมตรภายหลัง)
  double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}
