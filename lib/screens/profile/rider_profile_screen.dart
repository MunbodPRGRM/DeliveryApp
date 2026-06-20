import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_avatar.dart';

/// หน้าโปรไฟล์ไรเดอร์ — รูป ชื่อ เบอร์ ทะเบียนรถ และรูปยานพาหนะ
class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ไรเดอร์')),
      body: StreamBuilder<Rider>(
        stream: fs.streamRider(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Center(child: UserAvatar(photoUrl: r.photoUrl, name: r.name, radius: 56)),
              const SizedBox(height: 16),
              Center(
                child: Text(r.name.isEmpty ? '(ไม่มีชื่อ)' : r.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(r.phone,
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  avatar: const Icon(Icons.confirmation_number, size: 18),
                  label: Text('ทะเบียน ${r.licensePlate}'),
                ),
              ),
              const SizedBox(height: 16),
              if (r.vehiclePhotoUrl.isNotEmpty) ...[
                const Text('รูปยานพาหนะ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    r.vehiclePhotoUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                        height: 200, child: Icon(Icons.broken_image)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Column(
                  children: [
                    _infoTile(Icons.badge_outlined, 'ชื่อ', r.name),
                    const Divider(height: 1),
                    _infoTile(Icons.phone_outlined, 'เบอร์โทร', r.phone),
                    const Divider(height: 1),
                    _infoTile(Icons.directions_car_outlined, 'ทะเบียนรถ',
                        r.licensePlate),
                  ],
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
        title: Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        subtitle: Text(value.isEmpty ? '-' : value,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
      );
}
