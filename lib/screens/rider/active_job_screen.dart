import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/status_badge.dart';

/// หน้างานที่กำลังทำ: แผนที่ตำแหน่งไรเดอร์ real-time
/// + ปุ่มเปลี่ยนสถานะ (เช็คระยะ 20 เมตร + ถ่ายรูป)
/// ไรเดอร์ต้องอยู่หน้านี้จนส่งสำเร็จ (แสดงโดย home gate ไม่มีปุ่มย้อนกลับ)
class ActiveJobScreen extends StatefulWidget {
  final String shipmentId;
  const ActiveJobScreen({super.key, required this.shipmentId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _mapController = MapController();
  final _location = LocationService();

  late final String _uid;
  late final FirestoreService _fs;

  StreamSubscription<Position>? _posSub;
  LatLng? _current;
  bool _busy = false;
  String? _locError;
  bool _simulate = false; // โหมดจำลองตำแหน่ง (แตะแผนที่/ปุ่มเพื่อย้าย)

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthService>().currentUser!.uid;
    _fs = context.read<FirestoreService>();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final pos = await _location.getCurrentPosition();
      _onPosition(pos);
      _posSub = _location.positionStream().listen(_onPosition);
    } on LocationException catch (e) {
      if (mounted) setState(() => _locError = e.message);
    }
  }

  void _onPosition(Position pos) =>
      _setCurrent(LatLng(pos.latitude, pos.longitude));

  /// ตั้งตำแหน่งปัจจุบัน (ใช้ทั้งจาก GPS จริงและโหมดจำลอง)
  void _setCurrent(LatLng point) {
    if (mounted) setState(() => _current = point);
    _mapController.move(point, 16);
    // เขียนตำแหน่งขึ้น Firestore ให้ sender/receiver ติดตาม (ไม่รอผล)
    _fs.updateRiderLocation(_uid, point.latitude, point.longitude).ignore();
  }

  void _toggleSimulate(bool on) {
    setState(() {
      _simulate = on;
      _locError = null;
    });
    if (on) {
      _posSub?.cancel(); // หยุด GPS จริง ใช้ตำแหน่งจำลองแทน
      _posSub = null;
    } else {
      _startTracking(); // กลับไปใช้ GPS จริง
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<XFile?> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return ImagePicker()
        .pickImage(source: source, maxWidth: 1024, imageQuality: 80);
  }

  /// ดำเนินการเปลี่ยนสถานะ: เช็ค 20 ม. → ถ่ายรูป → อัพโหลด → อัพเดท
  Future<void> _advance(Shipment s, LatLng target) async {
    if (_current == null) return _showError('ยังไม่ได้ตำแหน่งปัจจุบัน');
    final cloudinary = context.read<CloudinaryService>();

    final dist = _location.distanceMeters(
      _current!.latitude,
      _current!.longitude,
      target.latitude,
      target.longitude,
    );
    if (dist > 20) {
      return _showError(
          'อยู่ห่างจากจุดหมาย ${dist.toStringAsFixed(0)} ม. ต้องไม่เกิน 20 ม.');
    }

    final photo = await _pickPhoto();
    if (photo == null) return _showError('ต้องถ่ายรูปประกอบสถานะ');

    setState(() => _busy = true);
    try {
      final url = await cloudinary.uploadImage(photo);
      if (s.status == ShipmentStatus.accepted) {
        await _fs.setPickedUp(s.id, url);
      } else if (s.status == ShipmentStatus.pickedUp) {
        await _fs.setDelivered(
            shipmentId: s.id, riderId: _uid, photoUrl: url);
        // สำเร็จ → home gate จะสลับกลับไปหน้าลิสท์งานเอง
      }
    } catch (e) {
      _showError('ดำเนินการไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยกเลิกการรับงาน?'),
        content: const Text('งานจะกลับไปเป็นงานว่างให้ไรเดอร์คนอื่นรับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ใช่'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยกเลิกงาน'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await _fs.cancelJob(shipmentId: widget.shipmentId, riderId: _uid);
      // สำเร็จ → home gate จะสลับกลับไปหน้าลิสท์งานเอง
    } catch (e) {
      _showError('ยกเลิกไม่สำเร็จ: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('งานที่กำลังทำ'),
        actions: [
          TextButton.icon(
            onPressed: _busy ? null : _cancelJob,
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text('ยกเลิกงาน',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<Shipment>(
        stream: _fs.streamShipment(widget.shipmentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          final pickup = LatLng(s.pickupLat, s.pickupLng);
          final dropoff = LatLng(s.dropoffLat, s.dropoffLng);
          // เป้าหมายปัจจุบัน: สถานะ 2 ไปจุดรับ, สถานะ 3 ไปจุดส่ง
          final target = s.status == ShipmentStatus.accepted ? pickup : dropoff;

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _current ?? pickup,
                    initialZoom: 15,
                    onTap: _simulate ? (_, point) => _setCurrent(point) : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.delivery_app_flutter',
                    ),
                    MarkerLayer(markers: [
                      _marker(pickup, Colors.red, Icons.location_on),
                      _marker(dropoff, Colors.green, Icons.location_on),
                      if (_current != null)
                        _marker(_current!, Colors.blue, Icons.my_location),
                    ]),
                  ],
                ),
              ),
              _bottomPanel(s, target, pickup, dropoff),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomPanel(
      Shipment s, LatLng target, LatLng pickup, LatLng dropoff) {
    final distText = _current == null
        ? null
        : '${_location.distanceMeters(_current!.latitude, _current!.longitude, target.latitude, target.longitude).toStringAsFixed(0)} ม.';
    final isPickup = s.status == ShipmentStatus.accepted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(status: s.status),
          const SizedBox(height: 8),
          if (_locError != null)
            Text(_locError!, style: const TextStyle(color: Colors.red))
          else
            Text(isPickup
                ? 'มุ่งหน้าไปจุดรับ${distText == null ? "" : " (ห่าง $distText)"}'
                : 'มุ่งหน้าไปจุดส่ง${distText == null ? "" : " (ห่าง $distText)"}'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('โหมดจำลองตำแหน่ง'),
            subtitle: Text(_simulate
                ? 'แตะแผนที่เพื่อย้ายตำแหน่ง หรือใช้ปุ่มลัด'
                : 'ใช้ GPS จริงของเครื่อง'),
            value: _simulate,
            onChanged: _busy ? null : _toggleSimulate,
          ),
          if (_simulate)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setCurrent(pickup),
                      icon: const Icon(Icons.south_west, size: 18),
                      label: const Text('ไปจุดรับ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setCurrent(dropoff),
                      icon: const Icon(Icons.flag, size: 18),
                      label: const Text('ไปจุดส่ง'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _advance(s, target),
              icon: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: Text(isPickup
                  ? 'ถึงจุดรับแล้ว — ยืนยันรับสินค้า'
                  : 'ถึงจุดส่งแล้ว — ยืนยันส่งสำเร็จ'),
            ),
          ),
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
