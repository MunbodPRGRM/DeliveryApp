import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_avatar.dart';
import '../location/manage_addresses_screen.dart';

/// หน้าโปรไฟล์ผู้ใช้ — แสดงรูป ชื่อ เบอร์ และจำนวนที่อยู่
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
      body: StreamBuilder<AppUser>(
        stream: fs.streamUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final u = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Center(child: UserAvatar(photoUrl: u.photoUrl, name: u.name, radius: 56)),
              const SizedBox(height: 16),
              Center(
                child: Text(u.name.isEmpty ? '(ไม่มีชื่อ)' : u.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(u.phone,
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    _infoTile(Icons.badge_outlined, 'ชื่อ', u.name),
                    const Divider(height: 1),
                    _infoTile(Icons.phone_outlined, 'เบอร์โทร', u.phone),
                    const Divider(height: 1),
                    _infoTile(Icons.account_circle_outlined, 'ประเภทบัญชี',
                        'ผู้ใช้ (Sender/Receiver)'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: Color(0xFFF4511E)),
                  title: const Text('ที่อยู่ของฉัน'),
                  subtitle: Text('${u.addresses.length} ที่อยู่'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageAddressesScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthService>().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('ออกจากระบบ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        subtitle: Text(value.isEmpty ? '-' : value,
            style: const TextStyle(
                color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
      );
}
