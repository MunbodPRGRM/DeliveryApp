import 'package:cloud_firestore/cloud_firestore.dart';

/// สถานะการจัดส่ง 4 ขั้นตามโจทย์
class ShipmentStatus {
  static const int waitingRider = 1; // รอไรเดอร์มารับสินค้า
  static const int accepted = 2; // ไรเดอร์รับงาน กำลังมารับสินค้า
  static const int pickedUp = 3; // รับสินค้าแล้ว กำลังไปส่ง
  static const int delivered = 4; // นำส่งสินค้าแล้ว

  static const labels = {
    waitingRider: 'รอไรเดอร์มารับสินค้า',
    accepted: 'ไรเดอร์กำลังมารับสินค้า',
    pickedUp: 'กำลังนำส่งสินค้า',
    delivered: 'นำส่งสินค้าแล้ว',
  };

  static String labelOf(int status) => labels[status] ?? 'ไม่ทราบสถานะ';
}

/// รายการส่งสินค้าหนึ่งรายการ — collection: shipments
class Shipment {
  final String id;
  final int status;
  final DateTime? createdAt;

  // ผู้ส่ง + จุดรับ
  final String senderId;
  final String senderName;
  final String senderPhone;
  final String pickupAddressText;
  final double pickupLat;
  final double pickupLng;

  // ผู้รับ + จุดส่ง
  final String receiverId;
  final String receiverName;
  final String receiverPhone;
  final String dropoffAddressText;
  final double dropoffLat;
  final double dropoffLng;

  // สินค้า
  final String itemDescription;
  final String itemPhotoUrl; // รูปสถานะ [1]

  // ไรเดอร์ (null จนกว่าจะมีคนรับ)
  final String? riderId;
  final String? riderName;
  final String? riderPhone;

  // รูปตามสถานะ
  final String? photoStatus3; // รับสินค้า
  final String? photoStatus4; // ส่งสำเร็จ

  const Shipment({
    required this.id,
    required this.status,
    this.createdAt,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    required this.pickupAddressText,
    required this.pickupLat,
    required this.pickupLng,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhone,
    required this.dropoffAddressText,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.itemDescription,
    required this.itemPhotoUrl,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.photoStatus3,
    this.photoStatus4,
  });

  factory Shipment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    double num2d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return Shipment(
      id: doc.id,
      status: (d['status'] as num?)?.toInt() ?? ShipmentStatus.waitingRider,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      senderId: (d['senderId'] ?? '') as String,
      senderName: (d['senderName'] ?? '') as String,
      senderPhone: (d['senderPhone'] ?? '') as String,
      pickupAddressText: (d['pickupAddressText'] ?? '') as String,
      pickupLat: num2d(d['pickupLat']),
      pickupLng: num2d(d['pickupLng']),
      receiverId: (d['receiverId'] ?? '') as String,
      receiverName: (d['receiverName'] ?? '') as String,
      receiverPhone: (d['receiverPhone'] ?? '') as String,
      dropoffAddressText: (d['dropoffAddressText'] ?? '') as String,
      dropoffLat: num2d(d['dropoffLat']),
      dropoffLng: num2d(d['dropoffLng']),
      itemDescription: (d['itemDescription'] ?? '') as String,
      itemPhotoUrl: (d['itemPhotoUrl'] ?? '') as String,
      riderId: d['riderId'] as String?,
      riderName: d['riderName'] as String?,
      riderPhone: d['riderPhone'] as String?,
      photoStatus3: d['photoStatus3'] as String?,
      photoStatus4: d['photoStatus4'] as String?,
    );
  }
}
