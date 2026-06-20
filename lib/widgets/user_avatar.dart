import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// รูปโปรไฟล์วงกลม — โชว์รูปจาก URL ถ้ามี ไม่งั้นแสดงอักษรย่อจากชื่อ
class UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 28,
  });

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.seed.withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
      child: hasPhoto
          ? null
          : Text(
              _initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppTheme.seed,
              ),
            ),
    );
  }
}
