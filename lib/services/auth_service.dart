import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/rider.dart';

/// ประเภทบัญชีในระบบ
enum AccountRole { user, rider }

/// โดเมน email ปลอมต่อ role (Firebase Auth บังคับ email ไม่ซ้ำ)
/// เบอร์เดียวกันจึงสมัครได้ทั้ง User และ Rider โดย password คนละตัว
const _domainByRole = {
  AccountRole.user: 'user.delivery.app',
  AccountRole.rider: 'rider.delivery.app',
};

/// แปลง error ของ Firebase Auth เป็นข้อความภาษาไทย
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// stream แจ้งเมื่อสถานะ login เปลี่ยน (ใช้ใน AuthGate)
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// ดู role จาก email ของผู้ที่ login อยู่ (ไว้ route หลัง auto-login)
  AccountRole? roleOfCurrentUser() {
    final email = _auth.currentUser?.email;
    if (email == null) return null;
    for (final entry in _domainByRole.entries) {
      if (email.endsWith('@${entry.value}')) return entry.key;
    }
    return null;
  }

  String _emailFor(String phone, AccountRole role) =>
      '$phone@${_domainByRole[role]}';

  /// สมัครบัญชี User
  Future<void> registerUser({
    required String phone,
    required String password,
    required String name,
  }) async {
    final cred = await _createAuthAccount(phone, password, AccountRole.user);
    final user = AppUser(uid: cred.user!.uid, phone: phone, name: name);
    await _firestore.collection('users').doc(cred.user!.uid).set(user.toMap());
  }

  /// สมัครบัญชี Rider
  Future<void> registerRider({
    required String phone,
    required String password,
    required String name,
    required String licensePlate,
  }) async {
    final cred = await _createAuthAccount(phone, password, AccountRole.rider);
    final rider = Rider(
      uid: cred.user!.uid,
      phone: phone,
      name: name,
      licensePlate: licensePlate,
    );
    await _firestore.collection('riders').doc(cred.user!.uid).set(rider.toMap());
  }

  Future<UserCredential> _createAuthAccount(
    String phone,
    String password,
    AccountRole role,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: _emailFor(phone, role),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e, role));
    }
  }

  /// เข้าระบบตาม role ที่เลือก (ปุ่ม User / Rider)
  Future<void> login({
    required String phone,
    required String password,
    required AccountRole role,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailFor(phone, role),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e, role));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e, AccountRole role) {
    final roleText = role == AccountRole.user ? 'ผู้ใช้' : 'ไรเดอร์';
    switch (e.code) {
      case 'email-already-in-use':
        return 'เบอร์นี้ถูกใช้สมัครบัญชี$roleText แล้ว';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'เบอร์โทรหรือรหัสผ่านไม่ถูกต้อง (บัญชี$roleText)';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป (อย่างน้อย 6 ตัวอักษร)';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      default:
        return 'เกิดข้อผิดพลาด: ${e.code}';
    }
  }
}
