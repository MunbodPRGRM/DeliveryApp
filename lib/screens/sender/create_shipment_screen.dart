import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/photo_picker_field.dart';
import '../location/manage_addresses_screen.dart';

/// สร้าง shipment: เลือกจุดรับ (ที่อยู่ตัวเอง) → ค้นหาผู้รับจากเบอร์
/// → เลือกที่อยู่ผู้รับจากลิสท์ → รายละเอียด + รูปสินค้า
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _phone = TextEditingController();
  final _itemDesc = TextEditingController();

  AppUser? _me; // ผู้ส่ง (สำหรับชื่อ/เบอร์/ที่อยู่)
  Address? _pickup; // ที่อยู่จุดรับ (ของผู้ส่ง)

  AppUser? _receiver; // ผู้รับที่ค้นเจอ
  Address? _dropoff; // ที่อยู่จุดส่ง (ของผู้รับ)

  XFile? _itemPhoto;
  bool _searching = false;
  bool _submitting = false;

  late final String _uid;
  late final FirestoreService _fs;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthService>().currentUser!.uid;
    _fs = context.read<FirestoreService>();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final me = await _fs.streamUser(_uid).first;
    if (mounted) setState(() => _me = me);
  }

  @override
  void dispose() {
    _phone.dispose();
    _itemDesc.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _searchReceiver() async {
    final phone = _phone.text.trim();
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _showError('กรอกเบอร์ผู้รับ 10 หลักให้ถูกต้อง');
      return;
    }
    setState(() {
      _searching = true;
      _receiver = null;
      _dropoff = null;
    });
    try {
      final found = await _fs.findUserByPhone(phone);
      if (found == null) {
        _showError('ไม่พบผู้ใช้ที่มีเบอร์นี้');
      } else if (found.uid == _uid) {
        _showError('ส่งให้ตัวเองไม่ได้');
      } else if (found.addresses.isEmpty) {
        _showError('ผู้รับยังไม่มีที่อยู่ในระบบ');
        setState(() => _receiver = found);
      } else {
        setState(() => _receiver = found);
      }
    } catch (e) {
      _showError('ค้นหาไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    if (_pickup == null) return _showError('เลือกที่อยู่จุดรับสินค้า');
    if (_receiver == null) return _showError('ค้นหาและเลือกผู้รับก่อน');
    if (_dropoff == null) return _showError('เลือกที่อยู่จุดส่งของผู้รับ');

    setState(() => _submitting = true);
    try {
      var itemPhotoUrl = '';
      if (_itemPhoto != null) {
        itemPhotoUrl =
            await context.read<CloudinaryService>().uploadImage(_itemPhoto!);
      }
      await _fs.createShipment({
        'senderId': _uid,
        'senderName': _me!.name,
        'senderPhone': _me!.phone,
        'pickupAddressText': _pickup!.addressText,
        'pickupLat': _pickup!.lat,
        'pickupLng': _pickup!.lng,
        'receiverId': _receiver!.uid,
        'receiverName': _receiver!.name,
        'receiverPhone': _receiver!.phone,
        'dropoffAddressText': _dropoff!.addressText,
        'dropoffLat': _dropoff!.lat,
        'dropoffLng': _dropoff!.lng,
        'itemDescription': _itemDesc.text.trim(),
        'itemPhotoUrl': itemPhotoUrl,
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างรายการส่งสำเร็จ')),
        );
      }
    } catch (e) {
      _showError('สร้างรายการไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างรายการส่ง')),
      body: me == null
          ? const Center(child: CircularProgressIndicator())
          : me.addresses.isEmpty
              ? _noAddress()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('1. จุดรับสินค้า (ที่อยู่ของคุณ)'),
                    RadioGroup<Address>(
                      groupValue: _pickup,
                      onChanged: (v) => setState(() => _pickup = v),
                      child: Column(
                        children: me.addresses
                            .map((a) => RadioListTile<Address>(
                                  value: a,
                                  title: Text(a.label),
                                  subtitle: Text(a.addressText),
                                ))
                            .toList(),
                      ),
                    ),
                    const Divider(height: 32),
                    _sectionTitle('2. ผู้รับ (ค้นหาจากเบอร์โทร)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'เบอร์โทรผู้รับ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _searching ? null : _searchReceiver,
                          child: _searching
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('ค้นหา'),
                        ),
                      ],
                    ),
                    if (_receiver != null) _receiverSection(),
                    const Divider(height: 32),
                    _sectionTitle('3. รายละเอียดสินค้า'),
                    TextField(
                      controller: _itemDesc,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดสินค้า (เช่น เอกสาร, อาหาร)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: PhotoPickerField(
                        file: _itemPhoto,
                        label: 'รูปสินค้า (ไม่บังคับ)',
                        circle: false,
                        onPicked: (f) => setState(() => _itemPhoto = f),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('สร้างรายการส่ง'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _receiverSection() {
    final r = _receiver!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(r.name),
            subtitle: Text(r.phone),
          ),
        ),
        if (r.addresses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('ผู้รับยังไม่มีที่อยู่ในระบบ',
                style: TextStyle(color: Colors.red)),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('เลือกที่อยู่จุดส่ง:'),
          ),
          RadioGroup<Address>(
            groupValue: _dropoff,
            onChanged: (v) => setState(() => _dropoff = v),
            child: Column(
              children: r.addresses
                  .map((a) => RadioListTile<Address>(
                        value: a,
                        title: Text(a.label),
                        subtitle: Text(a.addressText),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _noAddress() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('คุณยังไม่มีที่อยู่สำหรับเป็นจุดรับสินค้า',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageAddressesScreen(),
                  ),
                ),
                child: const Text('ไปเพิ่มที่อยู่'),
              ),
            ],
          ),
        ),
      );
}
