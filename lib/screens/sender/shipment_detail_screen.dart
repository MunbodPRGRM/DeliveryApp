import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_badge.dart';
import '../tracking/rider_tracking_screen.dart';

/// รายละเอียด shipment + สถานะ (อัพเดท real-time)
/// แผนที่ติดตามไรเดอร์ real-time จะเพิ่มในขั้นถัดไป
class ShipmentDetailScreen extends StatelessWidget {
  final String shipmentId;
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดการส่ง')),
      body: StreamBuilder<Shipment>(
        stream: fs.streamShipment(shipmentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: StatusBadge(status: s.status)),
              const SizedBox(height: 16),
              if (s.itemPhotoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(s.itemPhotoUrl, height: 180,
                      fit: BoxFit.cover, errorBuilder: (_, _, _) {
                    return const SizedBox(
                        height: 180, child: Icon(Icons.broken_image));
                  }),
                ),
              const SizedBox(height: 16),
              _info('สินค้า', s.itemDescription.isEmpty ? '-' : s.itemDescription),
              const Divider(),
              _info('ผู้รับ', '${s.receiverName} (${s.receiverPhone})'),
              _info('จุดส่ง', s.dropoffAddressText),
              const Divider(),
              _info('ผู้ส่ง', '${s.senderName} (${s.senderPhone})'),
              _info('จุดรับ', s.pickupAddressText),
              const Divider(),
              _info('ไรเดอร์',
                  s.riderId == null ? 'ยังไม่มีไรเดอร์รับงาน' : '${s.riderName} (${s.riderPhone})'),
              if (s.status >= ShipmentStatus.accepted &&
                  s.status <= ShipmentStatus.pickedUp)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RiderTrackingScreen(shipmentId: s.id),
                        ),
                      ),
                      icon: const Icon(Icons.map),
                      label: const Text('ดูตำแหน่งไรเดอร์ real-time'),
                    ),
                  ),
                ),
              if (s.photoStatus3 != null && s.photoStatus3!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('รูปตอนรับสินค้า'),
                const SizedBox(height: 8),
                Image.network(s.photoStatus3!, height: 160, fit: BoxFit.cover),
              ],
              if (s.photoStatus4 != null && s.photoStatus4!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('รูปตอนส่งสำเร็จ'),
                const SizedBox(height: 8),
                Image.network(s.photoStatus4!, height: 160, fit: BoxFit.cover),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
