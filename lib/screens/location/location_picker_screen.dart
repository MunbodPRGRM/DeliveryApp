import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/address.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';

/// เลือกพิกัด 2 ทางตามโจทย์:
///  1) จิ้มเลือกจุดบนแผนที่ (reverse geocode เติมที่อยู่ให้)
///  2) ค้นหาที่อยู่แล้วระบบ geocode ขึ้นหมุดให้
/// คืนค่าเป็น [Address] ผ่าน Navigator.pop เมื่อกดยืนยัน
class LocationPickerScreen extends StatefulWidget {
  /// ส่งที่อยู่เดิมเข้ามาเพื่อแก้ไข (null = เพิ่มใหม่)
  final Address? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  final _geocoding = GeocodingService();
  final _location = LocationService();

  final _label = TextEditingController();
  final _addressText = TextEditingController();
  final _search = TextEditingController();

  static const _bangkok = LatLng(13.7563, 100.5018);
  LatLng? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _label.text = init.label;
      _addressText.text = init.addressText;
      _selected = LatLng(init.lat, init.lng);
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _addressText.dispose();
    _search.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// จิ้มแผนที่ → ตั้งหมุด + reverse geocode เติมที่อยู่
  Future<void> _onTap(LatLng point) async {
    setState(() => _selected = point);
    try {
      final text = await _geocoding.reverse(point);
      if (mounted && text.isNotEmpty) _addressText.text = text;
    } on GeocodingException catch (e) {
      _showError(e.message);
    }
  }

  /// ค้นหาที่อยู่ → เลือกจากลิสท์ผลลัพธ์ → ขยับหมุด
  Future<void> _runSearch() async {
    if (_search.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final results = await _geocoding.search(_search.text);
      if (!mounted) return;
      if (results.isEmpty) {
        _showError('ไม่พบที่อยู่ตามคำค้น');
        return;
      }
      final picked = await showModalBottomSheet<GeoResult>(
        context: context,
        builder: (_) => ListView(
          children: results
              .map((r) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(r.displayName),
                    onTap: () => Navigator.pop(context, r),
                  ))
              .toList(),
        ),
      );
      if (picked != null) {
        setState(() {
          _selected = picked.latLng;
          _addressText.text = picked.displayName;
        });
        _mapController.move(picked.latLng, 16);
      }
    } on GeocodingException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ใช้ตำแหน่งปัจจุบัน (GPS)
  Future<void> _useCurrent() async {
    setState(() => _busy = true);
    try {
      final pos = await _location.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _selected = point);
      _mapController.move(point, 16);
      await _onTap(point);
    } on LocationException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirm() {
    if (_selected == null) {
      _showError('กรุณาเลือกตำแหน่งบนแผนที่');
      return;
    }
    if (_label.text.trim().isEmpty) {
      _showError('กรุณาตั้งชื่อที่อยู่ เช่น บ้าน / ที่ทำงาน');
      return;
    }
    Navigator.pop(
      context,
      Address(
        label: _label.text.trim(),
        addressText: _addressText.text.trim(),
        lat: _selected!.latitude,
        lng: _selected!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ?? _bangkok;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'เพิ่มที่อยู่' : 'แก้ไขที่อยู่'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                    onTap: (_, point) => _onTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.delivery_app_flutter',
                    ),
                    if (_selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
                // แถบค้นหา + ปุ่มตำแหน่งปัจจุบัน
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _search,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _runSearch(),
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาที่อยู่...',
                                border: InputBorder.none,
                                icon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ตำแหน่งปัจจุบัน',
                            icon: const Icon(Icons.my_location),
                            onPressed: _busy ? null : _useCurrent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_busy)
                  const Positioned(
                    top: 72,
                    left: 0,
                    right: 0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          // ฟอร์มรายละเอียดที่อยู่
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _label,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อที่อยู่ (เช่น บ้าน, ที่ทำงาน)',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressText,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดที่อยู่',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                if (_selected != null)
                  Text(
                    'พิกัด: ${_selected!.latitude.toStringAsFixed(5)}, '
                    '${_selected!.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันที่อยู่นี้'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
