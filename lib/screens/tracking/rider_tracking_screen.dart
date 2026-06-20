import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/rider.dart';
import '../../models/shipment.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_badge.dart';

/// ติดตามตำแหน่งไรเดอร์แบบ real-time ของ shipment หนึ่งรายการ
/// ใช้ได้ทั้งฝั่ง Sender และ Receiver
class RiderTrackingScreen extends StatefulWidget {
  final String shipmentId;
  const RiderTrackingScreen({super.key, required this.shipmentId});

  @override
  State<RiderTrackingScreen> createState() => _RiderTrackingScreenState();
}

class _RiderTrackingScreenState extends State<RiderTrackingScreen> {
  final _mapController = MapController();

  /// ขยับกล้องตามไรเดอร์ (ทำหลัง frame เพื่อไม่ชนกับ build)
  void _follow(LatLng point) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(point, 16);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามไรเดอร์')),
      body: StreamBuilder<Shipment>(
        stream: fs.streamShipment(widget.shipmentId),
        builder: (context, shipSnap) {
          if (!shipSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = shipSnap.data!;
          final pickup = LatLng(s.pickupLat, s.pickupLng);
          final dropoff = LatLng(s.dropoffLat, s.dropoffLng);

          if (s.riderId == null) {
            return const Center(child: Text('ยังไม่มีไรเดอร์รับงานนี้'));
          }

          return StreamBuilder<Rider>(
            stream: fs.streamRider(s.riderId!),
            builder: (context, riderSnap) {
              final rider = riderSnap.data;
              final riderPoint = (rider != null && rider.hasLocation)
                  ? LatLng(rider.currentLat!, rider.currentLng!)
                  : null;
              if (riderPoint != null) _follow(riderPoint);

              return Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: riderPoint ?? pickup,
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.delivery_app_flutter',
                        ),
                        MarkerLayer(markers: [
                          _marker(pickup, Colors.red, Icons.location_on),
                          _marker(dropoff, Colors.green, Icons.location_on),
                          if (riderPoint != null)
                            _marker(
                                riderPoint, Colors.blue, Icons.motorcycle),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(status: s.status),
                        const SizedBox(height: 8),
                        Text('ไรเดอร์: ${s.riderName} (${s.riderPhone})'),
                        if (riderPoint == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('รอสัญญาณตำแหน่งไรเดอร์...',
                                style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Marker _marker(LatLng point, Color color, IconData icon) => Marker(
        point: point,
        width: 40,
        height: 40,
        child: Icon(icon, color: color, size: 40),
      );
}
