import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/cloudinary_config.dart';

/// อัพโหลดรูปขึ้น Cloudinary ผ่าน unsigned upload preset (REST multipart)
/// คืนค่าเป็น secure_url ที่เอาไปเก็บเป็น field ใน Firestore
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadImage(XFile image) async {
    if (!CloudinaryConfig.isConfigured) {
      throw CloudinaryException(
          'ยังไม่ได้ตั้งค่า Cloudinary (lib/config/cloudinary_config.dart)');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await image.readAsBytes(),
        filename: image.name,
      ));

    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw CloudinaryException('อัพโหลดรูปไม่สำเร็จ (${streamed.statusCode})');
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    if (url == null) throw CloudinaryException('ไม่ได้รับ URL จาก Cloudinary');
    return url;
  }
}

class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);
  @override
  String toString() => message;
}
