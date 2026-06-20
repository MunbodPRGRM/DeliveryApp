import 'package:cloud_firestore/cloud_firestore.dart';

import 'address.dart';

/// บัญชีผู้ใช้ (User) — เป็นได้ทั้ง Sender และ Receiver
/// doc id = Firebase Auth uid, collection: users
class AppUser {
  final String uid;
  final String phone;
  final String name;
  final String photoUrl; // URL จาก Cloudinary (ว่างได้ตอนเพิ่งสมัคร)
  final List<Address> addresses;

  const AppUser({
    required this.uid,
    required this.phone,
    required this.name,
    this.photoUrl = '',
    this.addresses = const [],
  });

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'photoUrl': photoUrl,
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      phone: (data['phone'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      photoUrl: (data['photoUrl'] ?? '') as String,
      addresses: ((data['addresses'] ?? []) as List)
          .map((e) => Address.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
