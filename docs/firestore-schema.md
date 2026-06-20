# Firestore Schema — Delivery App

ร่างโครงสร้างข้อมูล Firestore ออกแบบให้ครอบ business rules ในโจทย์ และเน้นจุดให้คะแนนสูง
(real-time location ของไรเดอร์ + กันรับงานซ้อน)

> เอกสารวางแผน — ยังไม่ใช่โค้ด อ้างอิง context หลักที่ `../../CLAUDE.md`

## ภาพรวม: 3 collections

```
users/{uid}        ← บัญชีผู้ใช้ (Sender/Receiver เป็นคนเดียวกัน)
riders/{uid}       ← บัญชีไรเดอร์ (แยกจาก users)
shipments/{id}     ← รายการส่งแต่ละชิ้น
```

---

## 1. `users/{uid}` — doc id = Firebase Auth uid

| field | type | หมายเหตุ |
|---|---|---|
| `phone` | string | ใช้ค้นหาผู้รับ (ต้อง query ได้) |
| `name` | string | |
| `photoUrl` | string | URL จาก Cloudinary |
| `addresses` | array\<map\> | มีได้หลายที่ (ดูข้างล่าง) |
| `createdAt` | timestamp | |

แต่ละ element ใน `addresses`:

```json
{ "label": "บ้าน", "addressText": "...", "lat": 13.7563, "lng": 100.5018 }
```

> เก็บเป็น array ในตัว doc (ไม่แยก subcollection) เพราะจำนวนที่อยู่น้อย อ่านทีเดียวจบ

---

## 2. `riders/{uid}` — doc id = Firebase Auth uid

| field | type | หมายเหตุ |
|---|---|---|
| `phone` | string | |
| `name` | string | |
| `photoUrl` | string | รูปไรเดอร์ |
| `vehiclePhotoUrl` | string | รูปยานพาหนะ |
| `licensePlate` | string | ทะเบียนรถ |
| `currentShipmentId` | string \| null | **กุญแจกันรับงานซ้อน** — ถ้าไม่ null = กำลังมีงาน |
| `currentLat` / `currentLng` | number \| null | **ตำแหน่ง real-time** ไรเดอร์อัพเดทตอนวิ่งงาน |
| `locationUpdatedAt` | timestamp | |
| `createdAt` | timestamp | |

> ตำแหน่ง real-time เก็บที่ rider doc (แหล่งเดียว) ฝั่ง sender/receiver แค่ฟัง `snapshots()`
> ของ rider doc ที่ผูกกับ shipment ของตน

---

## 3. `shipments/{id}` — doc id = auto-generated

| กลุ่ม | field | type | หมายเหตุ |
|---|---|---|---|
| สถานะ | `status` | number (1–4) | 4 สถานะตามโจทย์ |
| | `createdAt` | timestamp | |
| ผู้ส่ง | `senderId` | string | uid |
| | `senderName`, `senderPhone` | string | *คัดลอกมาเก็บ* (ดูหมายเหตุ) |
| จุดรับ | `pickupAddressText` | string | เลือกจากที่อยู่ผู้ส่งตอนสร้าง |
| | `pickupLat`, `pickupLng` | number | ใช้เช็คระยะ 20 ม. |
| ผู้รับ | `receiverId` | string | ค้นหาจากเบอร์ |
| | `receiverName`, `receiverPhone` | string | *คัดลอกมาเก็บ* |
| จุดส่ง | `dropoffAddressText` | string | เลือกจาก **ลิสท์ที่อยู่ของผู้รับ** |
| | `dropoffLat`, `dropoffLng` | number | ใช้เช็คระยะ 20 ม. |
| สินค้า | `itemDescription` | string | รายละเอียด |
| | `itemPhotoUrl` | string | **รูปสถานะ [1]** (sender ถ่าย) |
| ไรเดอร์ | `riderId` | string \| null | **null = ยังไม่มีคนรับ** (กันรับซ้อน) |
| | `riderName`, `riderPhone` | string \| null | คัดลอกตอนรับงาน |
| รูปตามสถานะ | `photoStatus3` | string \| null | **รูปสถานะ [3]** (rider ถ่ายตอนรับของ) |
| | `photoStatus4` | string \| null | **รูปสถานะ [4]** (rider ถ่ายตอนส่งสำเร็จ) |
| เวลา | `acceptedAt`, `pickedUpAt`, `deliveredAt` | timestamp | เวลาเข้าสถานะ 2/3/4 |

### 4 สถานะ (`status`)

1. รอไรเดอร์มารับสินค้า
2. ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)
3. ไรเดอร์รับสินค้าแล้ว กำลังเดินทางไปส่ง
4. ไรเดอร์นำส่งสินค้าแล้ว

---

## การตัดสินใจสำคัญ 3 ข้อ (มีผลกับคะแนน)

### 1. เบอร์เดียวสมัครได้ทั้ง User และ Rider (password คนละตัว)

Firebase Auth บังคับ email ไม่ซ้ำ → แยก domain ตาม role:

- User: `0812345678@user.delivery.app`
- Rider: `0812345678@rider.delivery.app`

เบอร์เดียวกันจึงมี 2 บัญชีได้ และ "เข้าระบบถูกประเภท" ทำได้โดยเลือก domain ตามปุ่มที่กด

### 2. กันรับงานซ้อน → ใช้ Firestore transaction

ตอนไรเดอร์กดรับงาน เช็ค + เขียน 2 เงื่อนไขพร้อมกันแบบ atomic:

- `riders/{uid}.currentShipmentId == null` (ตัวเองว่าง)
- `shipments/{id}.riderId == null` (งานยังไม่มีคนรับ)

ผ่านทั้งคู่ค่อยเซ็ต `riderId` + `currentShipmentId` พร้อมกัน
→ กันได้ทั้งกรณีไรเดอร์รับ 2 งาน และ 2 คนแย่งงานเดียวกัน

### 3. คัดลอกชื่อ/เบอร์มาเก็บใน shipment (denormalize)

แสดงลิสท์ shipment หลายชิ้นโดยไม่ต้องไปดึง doc ของ user/rider ทุกตัว
→ อ่านน้อยลง ลิสท์เร็วขึ้น (Firestore คิดค่าตาม document read)
ข้อแลกเปลี่ยน: ถ้าผู้ใช้เปลี่ยนชื่อ ข้อมูลใน shipment เก่าจะไม่อัพเดทตาม (ยอมรับได้สำหรับงานนี้)

---

## Index ที่ต้องสร้าง

- `shipments` where `senderId ==` → ลิสท์ของผู้ส่ง
- `shipments` where `receiverId ==` → ลิสท์ของผู้รับ
- `shipments` where `status == 1` → ลิสท์งานว่างให้ไรเดอร์เลือก

> index แบบ field เดียวที่ใช้ equality Firestore สร้างให้อัตโนมัติ
> จะต้องสร้าง composite index เมื่อมี query ที่ผสมหลายเงื่อนไข เช่น `receiverId == ... AND status == ...`
