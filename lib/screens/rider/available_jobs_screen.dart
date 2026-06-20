import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'job_detail_screen.dart';

/// ลิสท์งานที่ยังว่าง (สถานะ 1) ให้ไรเดอร์เลือกรับ
/// แสดงเมื่อไรเดอร์ยังไม่มีงานค้าง
class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานที่รับได้'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Shipment>>(
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
          return ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = jobs[i];
              return ListTile(
                leading: const Icon(Icons.assignment_outlined),
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
              );
            },
          );
        },
      ),
    );
  }
}
