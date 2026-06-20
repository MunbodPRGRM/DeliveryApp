/// ค่าตั้งสำหรับอัพโหลดรูปขึ้น Cloudinary แบบ unsigned (ไม่ต้องมี backend)
///
/// วิธีหาค่า:
///  1. สมัคร https://cloudinary.com (ฟรี ไม่ต้องผูกบัตร)
///  2. cloudName: ดูได้ที่หน้า Dashboard (มุมบน "Cloud name" หรือใน API Environment)
///  3. uploadPreset: Settings (ไอคอนเฟือง) → Upload → Upload presets →
///     Add upload preset → ตั้ง Signing Mode = "Unsigned" → Save แล้วเอาชื่อมาใส่
///
/// หมายเหตุ: ค่าพวกนี้ฝังในแอป client อยู่แล้วโดยธรรมชาติ (unsigned)
/// ถ้ากังวลเรื่อง abuse ให้ตั้ง folder/ขนาดไฟล์จำกัดใน preset
class CloudinaryConfig {
  static const String cloudName = 'dyjkwehjg';
  static const String uploadPreset = 'delivery-app';

  static bool get isConfigured =>
      !cloudName.startsWith('PASTE_') && !uploadPreset.startsWith('PASTE_');
}
