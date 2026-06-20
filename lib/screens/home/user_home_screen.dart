import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../location/manage_addresses_screen.dart';
import '../receiver/received_shipments_screen.dart';
import '../sender/sent_shipments_screen.dart';

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
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('เข้าระบบเป็นผู้ใช้สำเร็จ ✅',
                textAlign: TextAlign.center),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('ที่อยู่ของฉัน'),
            subtitle: const Text('เพิ่ม/แก้ไขที่อยู่และพิกัด'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ManageAddressesScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('ส่งสินค้า'),
            subtitle: const Text('สร้างรายการส่งและติดตามสถานะ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SentShipmentsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.move_to_inbox_outlined),
            title: const Text('รับสินค้า'),
            subtitle: const Text('ดูสถานะและติดตามของที่ส่งมาถึงคุณ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ReceivedShipmentsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
