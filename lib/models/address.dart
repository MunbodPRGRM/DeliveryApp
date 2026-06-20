/// ที่อยู่หนึ่งรายการของผู้ใช้ พร้อมพิกัด GPS
/// ผู้ใช้มีได้หลายที่อยู่ (เก็บเป็น array ใน users doc)
class Address {
  final String label; // เช่น "บ้าน", "ที่ทำงาน"
  final String addressText;
  final double lat;
  final double lng;

  const Address({
    required this.label,
    required this.addressText,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'addressText': addressText,
        'lat': lat,
        'lng': lng,
      };

  factory Address.fromMap(Map<String, dynamic> map) => Address(
        label: (map['label'] ?? '') as String,
        addressText: (map['addressText'] ?? '') as String,
        lat: (map['lat'] as num?)?.toDouble() ?? 0,
        lng: (map['lng'] as num?)?.toDouble() ?? 0,
      );
}
