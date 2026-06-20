import 'package:cloud_firestore/cloud_firestore.dart';

/// บัญชีไรเดอร์ (Rider) — แยกจาก users
/// doc id = Firebase Auth uid, collection: riders
class Rider {
  final String uid;
  final String phone;
  final String name;
  final String photoUrl; // รูปไรเดอร์
  final String vehiclePhotoUrl; // รูปยานพาหนะ
  final String licensePlate; // ทะเบียนรถ
  final String? currentShipmentId; // != null = กำลังมีงาน (กันรับงานซ้อน)
  final double? currentLat; // ตำแหน่ง real-time
  final double? currentLng;

  const Rider({
    required this.uid,
    required this.phone,
    required this.name,
    this.photoUrl = '',
    this.vehiclePhotoUrl = '',
    this.licensePlate = '',
    this.currentShipmentId,
    this.currentLat,
    this.currentLng,
  });

  /// มีพิกัด real-time พร้อมแสดงบนแผนที่หรือยัง
  bool get hasLocation => currentLat != null && currentLng != null;

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'photoUrl': photoUrl,
        'vehiclePhotoUrl': vehiclePhotoUrl,
        'licensePlate': licensePlate,
        'currentShipmentId': currentShipmentId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Rider.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Rider(
      uid: doc.id,
      phone: (data['phone'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      photoUrl: (data['photoUrl'] ?? '') as String,
      vehiclePhotoUrl: (data['vehiclePhotoUrl'] ?? '') as String,
      licensePlate: (data['licensePlate'] ?? '') as String,
      currentShipmentId: data['currentShipmentId'] as String?,
      currentLat: (data['currentLat'] as num?)?.toDouble(),
      currentLng: (data['currentLng'] as num?)?.toDouble(),
    );
  }
}
