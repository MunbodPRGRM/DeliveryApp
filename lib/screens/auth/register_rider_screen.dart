import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/photo_picker_field.dart';
import 'login_screen.dart' show validatePhone;

/// สมัครบัญชีไรเดอร์ (Rider)
/// หมายเหตุ: รูปไรเดอร์ + รูปยานพาหนะ จะเพิ่มในขั้นถัดไป
class RegisterRiderScreen extends StatefulWidget {
  const RegisterRiderScreen({super.key});

  @override
  State<RegisterRiderScreen> createState() => _RegisterRiderScreenState();
}

class _RegisterRiderScreenState extends State<RegisterRiderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _plate = TextEditingController();
  XFile? _photo;
  XFile? _vehiclePhoto;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cloudinary = context.read<CloudinaryService>();
      var photoUrl = '';
      var vehicleUrl = '';
      if (_photo != null) photoUrl = await cloudinary.uploadImage(_photo!);
      if (_vehiclePhoto != null) {
        vehicleUrl = await cloudinary.uploadImage(_vehiclePhoto!);
      }
      if (!mounted) return;
      await context.read<AuthService>().registerRider(
            phone: _phone.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            licensePlate: _plate.text.trim(),
            photoUrl: photoUrl,
            vehiclePhotoUrl: vehicleUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      _showError(e.message);
    } on CloudinaryException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครไรเดอร์')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoPickerField(
                    file: _photo,
                    label: 'รูปไรเดอร์',
                    onPicked: (f) => setState(() => _photo = f),
                  ),
                  PhotoPickerField(
                    file: _vehiclePhoto,
                    label: 'รูปยานพาหนะ',
                    circle: false,
                    onPicked: (f) => setState(() => _vehiclePhoto = f),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรอกชื่อ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: validatePhone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plate,
                decoration: const InputDecoration(
                  labelText: 'ทะเบียนรถ',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรอกทะเบียนรถ'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่าน (อย่างน้อย 6 ตัว)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'รหัสผ่านอย่างน้อย 6 ตัวอักษร'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('สมัครสมาชิก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
