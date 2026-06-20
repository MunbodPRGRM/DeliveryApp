import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/rider.dart';
import '../../models/shipment.dart';
import '../../services/firestore_service.dart';

/// แผนที่รวม: แสดงตำแหน่งไรเดอร์ทุกคนของทุก shipment ที่กำลังจัดส่ง
/// (สถานะ 2-3) ในแผนที่เดียว — ใช้ได้ทั้ง Sender และ Receiver
class CombinedTrackingScreen extends StatefulWidget {
  final Stream<List<Shipment>> shipmentsStream;
  final String title;
  const CombinedTrackingScreen({
    super.key,
    required this.shipmentsStream,
    this.title = 'แผนที่รวมไรเดอร์',
  });

  @override
  State<CombinedTrackingScreen> createState() => _CombinedTrackingScreenState();
}

class _CombinedTrackingScreenState extends State<CombinedTrackingScreen> {
  final _mapController = MapController();
  late final FirestoreService _fs;

  StreamSubscription<List<Shipment>>? _shipSub;
  final Map<String, StreamSubscription<Rider>> _riderSubs = {};
  final Map<String, LatLng> _riderPos = {}; // riderId -> ตำแหน่ง

  List<Shipment> _active = [];
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _fs = context.read<FirestoreService>();
    _shipSub = widget.shipmentsStream.listen(_onShipments);
  }

  void _onShipments(List<Shipment> list) {
    final active = list
        .where((s) =>
            s.riderId != null &&
            s.status >= ShipmentStatus.accepted &&
            s.status <= ShipmentStatus.pickedUp)
        .toList();
    setState(() => _active = active);

    final riderIds = active.map((s) => s.riderId!).toSet();

    // ยกเลิก subscription ของไรเดอร์ที่ไม่ active แล้ว
    for (final id in _riderSubs.keys.toList()) {
      if (!riderIds.contains(id)) {
        _riderSubs.remove(id)?.cancel();
        _riderPos.remove(id);
      }
    }
    // เพิ่ม subscription ของไรเดอร์ใหม่
    for (final id in riderIds) {
      if (!_riderSubs.containsKey(id)) {
        _riderSubs[id] = _fs.streamRider(id).listen((r) {
          if (!mounted) return;
          setState(() {
            if (r.hasLocation) {
              _riderPos[id] = LatLng(r.currentLat!, r.currentLng!);
            }
          });
          _maybeFit();
        });
      }
    }
  }

  /// จัดกล้องให้เห็นทุกจุดครั้งแรกที่มีข้อมูล
  void _maybeFit() {
    if (_fitted) return;
    final points = _allPoints();
    if (points.isEmpty) return;
    _fitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(50),
      ));
    });
  }

  List<LatLng> _allPoints() {
    final pts = <LatLng>[];
    for (final s in _active) {
      pts.add(LatLng(s.pickupLat, s.pickupLng));
      pts.add(LatLng(s.dropoffLat, s.dropoffLng));
    }
    pts.addAll(_riderPos.values);
    return pts;
  }

  @override
  void dispose() {
    _shipSub?.cancel();
    for (final sub in _riderSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    for (final s in _active) {
      markers.add(_marker(
          LatLng(s.pickupLat, s.pickupLng), Colors.red, Icons.location_on));
      markers.add(_marker(
          LatLng(s.dropoffLat, s.dropoffLng), Colors.green, Icons.location_on));
    }
    for (final p in _riderPos.values) {
      markers.add(_marker(p, Colors.blue, Icons.motorcycle));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _active.isEmpty
          ? const Center(child: Text('ไม่มีรายการที่กำลังจัดส่งตอนนี้'))
          : FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(13.7563, 100.5018), // กรุงเทพฯ
                initialZoom: 11,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.delivery_app_flutter',
                ),
                MarkerLayer(markers: markers),
              ],
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
