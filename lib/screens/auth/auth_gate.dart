import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../home/rider_home_screen.dart';
import '../home/user_home_screen.dart';
import 'login_screen.dart';

/// คุมการ route หลัก: ยังไม่ login → LoginScreen
/// login แล้ว → เข้าหน้า home ตามประเภทบัญชี (อ่าน role จาก email)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return const LoginScreen();

        switch (auth.roleOfCurrentUser()) {
          case AccountRole.rider:
            return const RiderHomeScreen();
          case AccountRole.user:
            return const UserHomeScreen();
          case null:
            // email ไม่ตรง role ที่รู้จัก — กันค้าง ให้ออกจากระบบ
            return const LoginScreen();
        }
      },
    );
  }
}
