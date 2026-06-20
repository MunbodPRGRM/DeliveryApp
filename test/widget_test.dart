// Smoke test เบื้องต้น
// หมายเหตุ: หน้าจอจริงต้อง Firebase.initializeApp ก่อน build ได้
// การทดสอบ widget ที่ใช้ Firebase จะเพิ่มทีหลังเมื่อตั้ง Firebase emulator
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_app_flutter/main.dart';

void main() {
  test('DeliveryApp can be constructed', () {
    expect(const DeliveryApp(), isNotNull);
  });
}
