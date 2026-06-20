# delivery_app_flutter — Flutter App

แอป Flutter ของโปรเจกต์ Delivery App (เรียกไรเดอร์มารับ-ส่งสินค้า + ติดตามสถานะ/พิกัด real-time)

> Context หลักของโปรเจกต์ (โจทย์, tech stack, business rules, เกณฑ์คะแนน) อยู่ที่ `../CLAUDE.md`
> ไฟล์นี้คุมเฉพาะเรื่องของโค้ดฝั่ง Flutter

## สถานะปัจจุบัน

ยังเป็นโปรเจกต์ Flutter เปล่า (default counter app ใน `lib/main.dart`) — ยังไม่ได้เพิ่ม dependency
หรือเชื่อม Firebase/Cloudinary ใด ๆ ตาม stack ที่วางไว้

## คำสั่งที่ใช้บ่อย

```bash
flutter pub get              # ติดตั้ง dependencies หลังแก้ pubspec.yaml
flutter run                  # รันบน device/emulator ที่ต่ออยู่
flutter analyze              # ตรวจ lint/error (ใช้ analysis_options.yaml)
flutter test                 # รัน unit/widget tests ใน test/
dart format .                # จัดรูปแบบโค้ด
flutter build apk --release  # build APK ส่งงาน (deliverable หลัก)
flutter devices              # ดู device/emulator ที่ใช้ได้
```

## Environment

- Dart SDK: `^3.12.2` (ดู `pubspec.yaml`)
- Lints: `flutter_lints` ^6.0.0 ผ่าน `analysis_options.yaml`
- Target หลักที่ต้องส่ง: **Android (APK)** — โฟลเดอร์ `android/` คือตัวที่ต้องดูแลให้ build ได้จริง
- โฟลเดอร์ ios/linux/macos/windows/web มากับ scaffold แต่ไม่ใช่เป้าหมายส่งงาน

## โครงสร้าง

- `lib/` — ซอร์สโค้ดหลัก (ตอนนี้มีแค่ `main.dart`)
- `test/` — เทสต์
- `android/` — config ฝั่ง Android (จะต้องใส่ Firebase `google-services.json`, permission ตำแหน่ง/กล้อง ที่นี่)
- `pubspec.yaml` — dependencies + assets

## แนวทางโครงสร้างโค้ดที่จะทำต่อ (อิง stack ใน `../CLAUDE.md`)

Packages ที่ต้องเพิ่ม: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`,
`flutter_map`, `latlong2`, `geolocator`, `image_picker`, `http` (สำหรับอัพโหลด Cloudinary)

โครงที่แนะนำใน `lib/`:
- `models/` — User, Rider, Shipment, Address
- `services/` — auth, firestore, cloudinary upload, location/geolocator
- `screens/` — แยกตาม role: auth, sender, receiver, rider
- `widgets/` — UI ใช้ซ้ำ เช่น map view, status badge

## จุดที่ต้องระวัง (ตาม business rules + เกณฑ์คะแนน)

- **Real-time location** ของไรเดอร์บนแผนที่ ใช้ Firestore `snapshots()` listener (คะแนนสูงสุด อย่าทำเป็น refresh เอง)
- **กันรับงานซ้อน**: ใช้ Firestore transaction ตอน rider กดรับงาน (กันทั้ง 1 คนรับ 2 งาน และ 2 คนรับงานเดียวกัน)
- **เช็คระยะ 20 เมตร** ตอนรับ/ส่ง ใช้ `Geolocator.distanceBetween()`
- การเลือกพิกัด: จิ้มจากแผนที่ หรือ geocode ที่อยู่ผ่าน Nominatim (OSM)
- เลือกผู้รับต้องเป็นลิสท์จากการค้นหาเบอร์โทร ไม่ใช่กรอกเอง

## ข้อควรปฏิบัติ

- รัน `flutter analyze` ให้ผ่านก่อน commit
- API key / secret ที่ sensitive (Cloudinary, Firebase) อย่า hardcode ลง repo public
- คอมมิตด้วยบัญชีของแต่ละคนในทีม เพื่อให้มีประวัติการทำงานร่วมกันตาม deliverable
