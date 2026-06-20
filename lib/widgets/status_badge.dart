import 'package:flutter/material.dart';

import '../models/shipment.dart';

/// ป้ายแสดงสถานะ shipment (1-4) พร้อมสีตามขั้น
class StatusBadge extends StatelessWidget {
  final int status;
  const StatusBadge({super.key, required this.status});

  Color _color() {
    switch (status) {
      case ShipmentStatus.waitingRider:
        return Colors.orange;
      case ShipmentStatus.accepted:
        return Colors.blue;
      case ShipmentStatus.pickedUp:
        return Colors.purple;
      case ShipmentStatus.delivered:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$status. ${ShipmentStatus.labelOf(status)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
