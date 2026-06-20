import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/address.dart';
import '../models/app_user.dart';
import '../models/rider.dart';
import '../models/shipment.dart';

/// อ่าน/เขียนข้อมูลใน Firestore
/// ตอนนี้ครอบเฉพาะ users + addresses ส่วน shipments จะเพิ่มในขั้นถัดไป
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// ฟังข้อมูลผู้ใช้แบบ real-time (รวมลิสท์ที่อยู่)
  Stream<AppUser> streamUser(String uid) =>
      _userDoc(uid).snapshots().map(AppUser.fromDoc);

  /// บันทึกทั้งลิสท์ที่อยู่ (อ่าน-แก้-เขียนกลับจากฝั่งหน้าจอ)
  Future<void> saveAddresses(String uid, List<Address> addresses) =>
      _userDoc(uid).update({
        'addresses': addresses.map((a) => a.toMap()).toList(),
      });

  // ---------------- Shipments ----------------

  CollectionReference<Map<String, dynamic>> get _shipments =>
      _db.collection('shipments');

  /// ค้นหาผู้รับจากเบอร์โทร (ผู้รับเป็นบัญชี User) — คืน null ถ้าไม่พบ
  Future<AppUser?> findUserByPhone(String phone) async {
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromDoc(snap.docs.first);
  }

  /// สร้าง shipment ใหม่ (เริ่มที่สถานะ 1 รอไรเดอร์) — คืน id ที่สร้าง
  Future<String> createShipment(Map<String, dynamic> data) async {
    final ref = await _shipments.add({
      ...data,
      'status': ShipmentStatus.waitingRider,
      'riderId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// ลิสท์ shipment ที่ผู้ใช้คนนี้เป็นผู้ส่ง (เรียงใหม่→เก่าฝั่ง client
  /// เพื่อเลี่ยงการต้องสร้าง composite index)
  Stream<List<Shipment>> streamSentShipments(String senderId) => _shipments
      .where('senderId', isEqualTo: senderId)
      .snapshots()
      .map(_toSortedList);

  /// ลิสท์ shipment ที่ผู้ใช้คนนี้เป็นผู้รับ (ใช้ในฝั่ง Receiver ขั้นถัดไป)
  Stream<List<Shipment>> streamReceivedShipments(String receiverId) =>
      _shipments
          .where('receiverId', isEqualTo: receiverId)
          .snapshots()
          .map(_toSortedList);

  /// ฟัง shipment รายตัวแบบ real-time (หน้ารายละเอียด)
  Stream<Shipment> streamShipment(String id) =>
      _shipments.doc(id).snapshots().map(Shipment.fromDoc);

  // ---------------- Rider ----------------

  DocumentReference<Map<String, dynamic>> _riderDoc(String uid) =>
      _db.collection('riders').doc(uid);

  /// ฟังข้อมูลไรเดอร์ (ใช้เช็ค currentShipmentId ว่ามีงานค้างไหม)
  Stream<Rider> streamRider(String uid) =>
      _riderDoc(uid).snapshots().map(Rider.fromDoc);

  /// งานที่ยังว่าง (สถานะ 1) ให้ไรเดอร์เลือกรับ
  Stream<List<Shipment>> streamAvailableJobs() => _shipments
      .where('status', isEqualTo: ShipmentStatus.waitingRider)
      .snapshots()
      .map(_toSortedList);

  /// อัพเดทตำแหน่ง real-time ของไรเดอร์ (sender/receiver ใช้ติดตาม)
  Future<void> updateRiderLocation(String uid, double lat, double lng) =>
      _riderDoc(uid).update({
        'currentLat': lat,
        'currentLng': lng,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

  /// รับงาน — ใช้ transaction กันรับงานซ้อน (atomic)
  /// เงื่อนไข: ไรเดอร์ต้องว่าง + งานต้องยังไม่มีคนรับและยังสถานะ 1
  Future<void> acceptJob({
    required String shipmentId,
    required Rider rider,
  }) async {
    final shipmentRef = _shipments.doc(shipmentId);
    final riderRef = _riderDoc(rider.uid);

    await _db.runTransaction((tx) async {
      final riderSnap = await tx.get(riderRef);
      final current = riderSnap.data()?['currentShipmentId'];
      if (current != null) {
        throw FirestoreServiceException('คุณมีงานที่ยังไม่เสร็จอยู่');
      }

      final shipSnap = await tx.get(shipmentRef);
      final ship = shipSnap.data() ?? {};
      if (ship['riderId'] != null ||
          ship['status'] != ShipmentStatus.waitingRider) {
        throw FirestoreServiceException('งานนี้ถูกไรเดอร์คนอื่นรับไปแล้ว');
      }

      tx.update(shipmentRef, {
        'riderId': rider.uid,
        'riderName': rider.name,
        'riderPhone': rider.phone,
        'status': ShipmentStatus.accepted,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      tx.update(riderRef, {'currentShipmentId': shipmentId});
    });
  }

  /// ยกเลิกการรับงาน → คืนงานกลับสถานะ 1 + ปลดล็อกไรเดอร์ (batch atomic)
  /// ล้างข้อมูลไรเดอร์/รูป/เวลา เพื่อให้งานกลับไปว่างเหมือนเดิม
  Future<void> cancelJob({
    required String shipmentId,
    required String riderId,
  }) async {
    final batch = _db.batch();
    batch.update(_shipments.doc(shipmentId), {
      'status': ShipmentStatus.waitingRider,
      'riderId': null,
      'riderName': null,
      'riderPhone': null,
      'acceptedAt': null,
      'pickedUpAt': null,
      'photoStatus3': null,
    });
    batch.update(_riderDoc(riderId), {'currentShipmentId': null});
    await batch.commit();
  }

  /// ยืนยันรับสินค้า → สถานะ 3 (พร้อมรูป)
  Future<void> setPickedUp(String shipmentId, String photoUrl) =>
      _shipments.doc(shipmentId).update({
        'status': ShipmentStatus.pickedUp,
        'photoStatus3': photoUrl,
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

  /// ยืนยันส่งสำเร็จ → สถานะ 4 + ปลดไรเดอร์ให้รับงานใหม่ได้ (batch atomic)
  Future<void> setDelivered({
    required String shipmentId,
    required String riderId,
    required String photoUrl,
  }) async {
    final batch = _db.batch();
    batch.update(_shipments.doc(shipmentId), {
      'status': ShipmentStatus.delivered,
      'photoStatus4': photoUrl,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
    batch.update(_riderDoc(riderId), {'currentShipmentId': null});
    await batch.commit();
  }

  List<Shipment> _toSortedList(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(Shipment.fromDoc).toList();
    list.sort((a, b) {
      final at = a.createdAt;
      final bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return -1; // เพิ่งสร้าง (serverTimestamp ยังไม่ลง) ให้อยู่บนสุด
      if (bt == null) return 1;
      return bt.compareTo(at);
    });
    return list;
  }
}

class FirestoreServiceException implements Exception {
  final String message;
  FirestoreServiceException(this.message);
  @override
  String toString() => message;
}
