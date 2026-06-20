import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rider.dart';
import '../../models/shipment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/user_avatar.dart';
import '../profile/rider_profile_screen.dart';
import 'job_detail_screen.dart';

/// ลิสท์งานที่ยังว่าง (สถานะ 1) ให้ไรเดอร์เลือกรับ
/// แสดงเมื่อไรเดอร์ยังไม่มีงานค้าง
class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final uid = context.read<AuthService>().currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานที่รับได้'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'โปรไฟล์',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RiderProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<Rider>(
            stream: fs.streamRider(uid),
            builder: (context, snapshot) {
              final r = snapshot.data;
              return _RiderHeader(
                photoUrl: r?.photoUrl ?? '',
                name: r?.name ?? '',
                plate: r?.licensePlate ?? '',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RiderProfileScreen(),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Shipment>>(
              stream: fs.streamAvailableJobs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final jobs = snapshot.data!;
                if (jobs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีงานว่างตอนนี้'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: jobs.length,
                  itemBuilder: (context, i) {
                    final s = jobs[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined,
                            color: Color(0xFF00897B)),
                        title: Text(s.itemDescription.isEmpty
                            ? 'พัสดุ'
                            : s.itemDescription),
                        subtitle: Text(
                          'รับ: ${s.pickupAddressText}\nส่ง: ${s.dropoffAddressText}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(shipmentId: s.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// แถบโปรไฟล์ไรเดอร์ด้านบนหน้าลิสท์งาน
class _RiderHeader extends StatelessWidget {
  final String photoUrl;
  final String name;
  final String plate;
  final VoidCallback onTap;

  const _RiderHeader({
    required this.photoUrl,
    required this.name,
    required this.plate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(photoUrl: photoUrl, name: name, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'ไรเดอร์' : name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    if (plate.isNotEmpty)
                      Text('ทะเบียน $plate',
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
