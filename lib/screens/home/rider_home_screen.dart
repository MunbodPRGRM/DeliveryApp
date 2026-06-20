import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

/// หน้าหลักของไรเดอร์ — placeholder
/// ขั้นถัดไปจะใส่: ลิสท์งานว่าง, รับงาน (กันซ้อน), แผนที่ตำแหน่งตัวเอง
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าไรเดอร์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('เข้าระบบเป็นไรเดอร์สำเร็จ ✅\n(หน้ารับงานจะทำขั้นถัดไป)',
            textAlign: TextAlign.center),
      ),
    );
  }
}
