import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'location_picker_screen.dart';

/// จัดการที่อยู่ของผู้ใช้ — มีได้หลายที่ (ตามโจทย์)
class ManageAddressesScreen extends StatelessWidget {
  const ManageAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final fs = context.read<FirestoreService>();

    Future<void> save(List<Address> addresses) async {
      try {
        await fs.saveAddresses(uid, addresses);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
        }
      }
    }

    Future<void> addOrEdit(List<Address> current, [int? index]) async {
      final result = await Navigator.of(context).push<Address>(
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initial: index != null ? current[index] : null,
          ),
        ),
      );
      if (result == null) return;
      final updated = [...current];
      if (index != null) {
        updated[index] = result;
      } else {
        updated.add(result);
      }
      await save(updated);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ที่อยู่ของฉัน')),
      body: StreamBuilder<AppUser>(
        stream: fs.streamUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data!.addresses;
          if (addresses.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีที่อยู่\nกดปุ่ม + เพื่อเพิ่ม',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = addresses[i];
              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(a.label),
                subtitle: Text(
                  '${a.addressText}\n(${a.lat.toStringAsFixed(5)}, '
                  '${a.lng.toStringAsFixed(5)})',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => addOrEdit(addresses, i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final updated = [...addresses]..removeAt(i);
                        await save(updated);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          // อ่านลิสท์ปัจจุบันจาก stream ผ่าน FAB แยก: ดึงสด ๆ ตอนกด
          return FloatingActionButton.extended(
            onPressed: () async {
              final user = await fs.streamUser(uid).first;
              await addOrEdit(user.addresses);
            },
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มที่อยู่'),
          );
        },
      ),
    );
  }
}
