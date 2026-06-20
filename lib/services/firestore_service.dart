import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/address.dart';
import '../models/app_user.dart';

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
}
