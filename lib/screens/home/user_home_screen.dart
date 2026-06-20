import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_avatar.dart';
import '../location/manage_addresses_screen.dart';
import '../profile/user_profile_screen.dart';
import '../receiver/received_shipments_screen.dart';
import '../sender/sent_shipments_screen.dart';

/// หน้าหลักของผู้ใช้ (Sender/Receiver) — เมนูหลักแบบการ์ด
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();
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
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          StreamBuilder<AppUser>(
            stream: fs.streamUser(uid),
            builder: (context, snapshot) {
              final u = snapshot.data;
              return _ProfileHeader(
                photoUrl: u?.photoUrl ?? '',
                name: u?.name ?? '',
                phone: u?.phone ?? '',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserProfileScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _MenuCard(
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF00897B),
            title: 'ส่งสินค้า',
            subtitle: 'สร้างรายการส่งและติดตามสถานะ',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SentShipmentsScreen()),
            ),
          ),
          _MenuCard(
            icon: Icons.move_to_inbox_outlined,
            color: const Color(0xFF3949AB),
            title: 'รับสินค้า',
            subtitle: 'ดูสถานะและติดตามของที่ส่งมาถึงคุณ',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ReceivedShipmentsScreen()),
            ),
          ),
          _MenuCard(
            icon: Icons.location_on_outlined,
            color: const Color(0xFFF4511E),
            title: 'ที่อยู่ของฉัน',
            subtitle: 'เพิ่ม/แก้ไขที่อยู่และพิกัด',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageAddressesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// แถบโปรไฟล์ด้านบน — รูป + ชื่อ + เบอร์ แตะเพื่อเข้าหน้าโปรไฟล์
class _ProfileHeader extends StatelessWidget {
  final String photoUrl;
  final String name;
  final String phone;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.photoUrl,
    required this.name,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(photoUrl: photoUrl, name: name, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สวัสดี 👋',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(name.isEmpty ? 'ผู้ใช้' : name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (phone.isNotEmpty)
                      Text(phone,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// การ์ดเมนูหลัก พร้อมไอคอนสีในกล่องมน
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
