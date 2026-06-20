import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// รายละเอียดงานก่อนรับ + แผนที่จุดรับ (แดง) และจุดส่ง (เขียว)
/// กดรับงาน → transaction กันรับงานซ้อน
class JobDetailScreen extends StatefulWidget {
  final String shipmentId;
  const JobDetailScreen({super.key, required this.shipmentId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _accepting = false;

  Future<void> _accept(Shipment s) async {
    setState(() => _accepting = true);
    try {
      final fs = context.read<FirestoreService>();
      final uid = context.read<AuthService>().currentUser!.uid;
      final rider = await fs.streamRider(uid).first;
      await fs.acceptJob(shipmentId: s.id, rider: rider);
      if (mounted) {
        Navigator.of(context).pop(); // กลับ → home gate จะพาเข้าหน้างาน
      }
    } on FirestoreServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        Navigator.of(context).pop(); // งานถูกรับไปแล้ว ปิดหน้านี้
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('รับงานไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดงาน')),
      body: StreamBuilder<Shipment>(
        stream: fs.streamShipment(widget.shipmentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          final pickup = LatLng(s.pickupLat, s.pickupLng);
          final dropoff = LatLng(s.dropoffLat, s.dropoffLng);
          final taken = s.status != ShipmentStatus.waitingRider;

          return Column(
            children: [
              SizedBox(
                height: 260,
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds(pickup, dropoff),
                      padding: const EdgeInsets.all(50),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.delivery_app_flutter',
                    ),
                    MarkerLayer(markers: [
                      _marker(pickup, Colors.red),
                      _marker(dropoff, Colors.green),
                    ]),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text('จุดรับ: ${s.pickupAddressText}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text('จุดส่ง: ${s.dropoffAddressText}')),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('สินค้า: ${s.itemDescription.isEmpty ? "-" : s.itemDescription}'),
                    const SizedBox(height: 8),
                    Text('ผู้ส่ง: ${s.senderName} (${s.senderPhone})'),
                    Text('ผู้รับ: ${s.receiverName} (${s.receiverPhone})'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (taken || _accepting) ? null : () => _accept(s),
                    icon: _accepting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: Text(taken ? 'งานนี้ถูกรับไปแล้ว' : 'รับงานนี้'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Marker _marker(LatLng point, Color color) => Marker(
        point: point,
        width: 40,
        height: 40,
        child: Icon(Icons.location_on, color: color, size: 40),
      );
}
