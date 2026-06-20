import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/cloudinary_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

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
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<CloudinaryService>(create: (_) => CloudinaryService()),
      ],
      child: MaterialApp(
        title: 'Delivery App',
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}
