import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

/// หน้าหลักของผู้ใช้ (Sender/Receiver) — placeholder
/// ขั้นถัดไปจะใส่: สร้าง shipment, ลิสท์ของที่ส่ง/ของที่รับ, แผนที่ไรเดอร์
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าผู้ใช้'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('เข้าระบบเป็นผู้ใช้สำเร็จ ✅\n(หน้าส่ง/รับสินค้าจะทำขั้นถัดไป)',
            textAlign: TextAlign.center),
      ),
    );
  }
}
