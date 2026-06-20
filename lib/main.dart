import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePlaceholderScreen(),
    );
  }
}

/// หน้าจอชั่วคราว ยืนยันว่า Firebase เชื่อมต่อสำเร็จ
/// จะถูกแทนที่ด้วยหน้า Auth (เลือก User/Rider) ในขั้นถัดไป
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appName = Firebase.app().name;
    final projectId = Firebase.app().options.projectId;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery App')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Firebase เชื่อมต่อสำเร็จ ✅',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('app: $appName'),
              Text('project: $projectId'),
              const SizedBox(height: 16),
              const Text(
                'ขั้นถัดไป: ทำหน้าสมัคร/เข้าระบบ (User/Rider)',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
