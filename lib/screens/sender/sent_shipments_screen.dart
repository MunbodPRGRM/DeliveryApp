import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_badge.dart';
import '../tracking/combined_tracking_screen.dart';
import 'create_shipment_screen.dart';
import 'shipment_detail_screen.dart';

/// ลิสท์รายการที่ผู้ใช้คนนี้เป็นผู้ส่ง (มีได้หลายรายการ)
class SentShipmentsScreen extends StatelessWidget {
  const SentShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการที่ฉันส่ง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'แผนที่รวมไรเดอร์',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CombinedTrackingScreen(
                  shipmentsStream: fs.streamSentShipments(uid),
                  title: 'ไรเดอร์ที่กำลังส่งของฉัน',
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Shipment>>(
        stream: fs.streamSentShipments(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการส่ง\nกดปุ่ม + เพื่อสร้าง',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final s = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF00897B)),
                  title: Text('ถึง: ${s.receiverName} (${s.receiverPhone})'),
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateShipmentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('ส่งสินค้า'),
      ),
    );
  }
}
