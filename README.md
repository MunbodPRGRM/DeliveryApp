# Delivery App 🛵

แอปพลิเคชันเรียกไรเดอร์มารับ-ส่งสินค้า พร้อมติดตามสถานะและตำแหน่งไรเดอร์แบบ real-time
(Mini Project #2 - 2568)

## ฟีเจอร์หลัก

**ผู้ใช้ (User) — เป็นได้ทั้งผู้ส่งและผู้รับ**
- สมัคร/เข้าระบบด้วยเบอร์โทร + รหัสผ่าน พร้อมรูปโปรไฟล์
- จัดการที่อยู่ได้หลายที่ เลือกพิกัดจากแผนที่ หรือค้นหาที่อยู่แล้ว geocode ให้
- **ส่งสินค้า:** ค้นหาผู้รับจากเบอร์ → เลือกที่อยู่ผู้รับจากลิสท์ → แนบรูปสินค้า
- **รับสินค้า:** ดูลิสท์ของที่ส่งมาถึงตน + สถานะ
- ติดตามตำแหน่งไรเดอร์ **real-time** บนแผนที่ (รายชิ้น หรือรวมหลายคันในแผนที่เดียว)

**ไรเดอร์ (Rider)**
- สมัครด้วยเบอร์เดียวกับ User ได้ (รหัสผ่านคนละตัว) พร้อมรูปไรเดอร์/ยานพาหนะ/ทะเบียน
- ดูลิสท์งานว่าง + แผนที่จุดรับ-ส่งก่อนรับงาน
- **รับงานได้ครั้งละ 1 งาน กันรับซ้อนด้วย Firestore transaction**
- หน้าแผนที่ตำแหน่งตัวเอง real-time + เปลี่ยนสถานะ (เช็คระยะ ≤ 20 เมตร + ถ่ายรูปทุกสถานะ)
- โหมดจำลองตำแหน่ง (ทดสอบ/พรีเซนต์โดยไม่ต้องเดินจริง) + ปุ่มยกเลิกงาน

## สถานะการจัดส่ง

1. รอไรเดอร์มารับสินค้า → 2. ไรเดอร์กำลังมารับ → 3. กำลังนำส่ง → 4. ส่งสำเร็จ

## Tech Stack

| ส่วน | ใช้ |
|---|---|
| Frontend | Flutter (Material 3) |
| State | Provider |
| Auth + Database | Firebase Auth + Cloud Firestore (real-time ผ่าน `snapshots()`) |
| รูปภาพ | Cloudinary (unsigned upload) |
| แผนที่ | OpenStreetMap ผ่าน `flutter_map` + `latlong2` |
| Geocoding | Nominatim (OSM) |
| ระยะทาง/GPS | `geolocator` |

## โครงสร้างโปรเจกต์

```
lib/
├── models/        # AppUser, Rider, Address, Shipment
├── services/      # auth, firestore, location, geocoding, cloudinary
├── screens/
│   ├── auth/      # login, register (user/rider), auth gate
│   ├── home/      # user/rider home
│   ├── location/  # เลือกพิกัด + จัดการที่อยู่
│   ├── sender/    # สร้าง/ลิสท์/รายละเอียด shipment
│   ├── receiver/  # ลิสท์ของที่รับ
│   ├── rider/     # ลิสท์งาน, รายละเอียด, งานที่กำลังทำ (แผนที่)
│   ├── tracking/  # ติดตามไรเดอร์ real-time (รายชิ้น + รวม)
│   └── profile/   # โปรไฟล์ user/rider
├── widgets/       # status_badge, photo_picker_field, user_avatar
└── theme/         # ธีมกลาง (โทน Teal)
```

## การตั้งค่าก่อนรัน

1. **Firebase** — โปรเจกต์เชื่อมผ่าน `flutterfire configure` แล้ว (`lib/firebase_options.dart`)
   - เปิด **Authentication → Email/Password**
   - สร้าง **Cloud Firestore**
   - deploy กฎความปลอดภัย: `firebase deploy --only firestore:rules`
2. **Cloudinary** — กรอกค่าใน `lib/config/cloudinary_config.dart`
   (`cloudName` + unsigned `uploadPreset`)

## รันและ build

```bash
flutter pub get
flutter run                  # รันบน emulator/มือถือ (Android)
flutter build apk --release  # สร้าง APK ส่งงาน
```

> APK ที่ได้: `build/app/outputs/flutter-apk/app-release.apk`
> หมายเหตุ: เป้าหมายคือ **Android** — Firebase Auth/Firestore ไม่รองรับ Windows desktop

## หมายเหตุการพัฒนา

- ปิด Kotlin incremental compilation (`android/gradle.properties`) เพื่อเลี่ยงบั๊ก build บน Windows
- เบอร์เดียวสมัครได้ทั้ง User และ Rider โดยแยกผ่าน email domain
  (`<phone>@user.delivery.app` / `<phone>@rider.delivery.app`)
- โครงสร้างข้อมูล Firestore: ดู `docs/firestore-schema.md`
