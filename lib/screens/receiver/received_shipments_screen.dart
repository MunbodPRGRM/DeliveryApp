import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_badge.dart';
import '../sender/shipment_detail_screen.dart';
import '../tracking/combined_tracking_screen.dart';

/// ลิสท์รายการที่ผู้ใช้คนนี้เป็นผู้รับ (ดูสถานะ + ติดตามไรเดอร์)
class ReceivedShipmentsScreen extends StatelessWidget {
  const ReceivedShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการที่ส่งมาถึงฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'แผนที่รวมไรเดอร์',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CombinedTrackingScreen(
                  shipmentsStream: fs.streamReceivedShipments(uid),
                  title: 'ไรเดอร์ที่กำลังส่งมาถึงฉัน',
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Shipment>>(
        stream: fs.streamReceivedShipments(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('ยังไม่มีสินค้าที่ส่งมาถึงคุณ'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = items[i];
              return ListTile(
                leading: const Icon(Icons.move_to_inbox_outlined),
                title: Text('จาก: ${s.senderName} (${s.senderPhone})'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: StatusBadge(status: s.status),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShipmentDetailScreen(shipmentId: s.id),
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
