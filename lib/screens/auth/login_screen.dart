import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'register_user_screen.dart';
import 'register_rider_screen.dart';

/// หน้าเข้าสู่ระบบ — เลือกประเภทบัญชี (User/Rider) ก่อน login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  AccountRole _role = AccountRole.user;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().login(
            phone: _phone.text.trim(),
            password: _password.text,
            role: _role,
          );
      // สำเร็จ → AuthGate จะสลับหน้าให้เอง
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goRegister() {
    final page = _role == AccountRole.user
        ? const RegisterUserScreen()
        : const RegisterRiderScreen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.seed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping,
                      size: 52, color: AppTheme.seed),
                ),
                const SizedBox(height: 12),
                const Text('Delivery App',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('ส่งของถึงมือผู้รับ',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                SegmentedButton<AccountRole>(
                  segments: const [
                    ButtonSegment(
                      value: AccountRole.user,
                      label: Text('ผู้ใช้'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: AccountRole.rider,
                      label: Text('ไรเดอร์'),
                      icon: Icon(Icons.motorcycle),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: 16),
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
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'กรอกรหัสผ่าน' : null,
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
                        : const Text('เข้าสู่ระบบ'),
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : _goRegister,
                  child: Text(
                    'ยังไม่มีบัญชี? สมัคร'
                    '${_role == AccountRole.user ? "ผู้ใช้" : "ไรเดอร์"}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ตรวจเบอร์โทรไทย 10 หลักขึ้นต้น 0 (ใช้ร่วมหลายหน้า)
String? validatePhone(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'กรอกเบอร์โทร';
  if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
    return 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';
  }
  return null;
}
