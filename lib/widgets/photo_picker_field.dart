import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// ช่องเลือกรูป — แตะเพื่อถ่าย/เลือกจากคลัง แล้วโชว์ตัวอย่าง
/// ใช้ซ้ำได้: รูปโปรไฟล์ (circle) และรูปยานพาหนะ (สี่เหลี่ยม)
class PhotoPickerField extends StatelessWidget {
  final XFile? file;
  final String label;
  final bool circle;
  final ValueChanged<XFile> onPicked;

  const PhotoPickerField({
    super.key,
    required this.file,
    required this.label,
    required this.onPicked,
    this.circle = true,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final preview = file != null
        ? Image.file(File(file!.path), fit: BoxFit.cover)
        : Icon(Icons.add_a_photo, size: 36, color: Colors.grey.shade600);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pick(context),
          child: circle
              ? CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      file != null ? FileImage(File(file!.path)) : null,
                  child: file == null
                      ? Icon(Icons.add_a_photo,
                          size: 32, color: Colors.grey.shade600)
                      : null,
                )
              : Container(
                  width: 140,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: preview,
                ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
