import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../rider/active_job_screen.dart';
import '../rider/available_jobs_screen.dart';

/// gate ฝั่งไรเดอร์:
///  - มี currentShipmentId (งานค้าง) → ล็อกอยู่หน้างาน (ActiveJobScreen)
///  - ไม่มี → ดูลิสท์งานว่าง (AvailableJobsScreen)
/// ตรงข้อกำหนด: หลังรับงานต้องอยู่หน้าแผนที่จนส่งสำเร็จ
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();

    return StreamBuilder<Rider>(
      stream: fs.streamRider(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final active = snapshot.data!.currentShipmentId;
        if (active != null) {
          return ActiveJobScreen(shipmentId: active);
        }
        return const AvailableJobsScreen();
      },
    );
  }
}
