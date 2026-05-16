import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final cfg = _getConfig(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.$1.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cfg.$1, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            cfg.$2,
            style: TextStyle(
              color: cfg.$1,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, String) _getConfig(String status) {
    switch (status) {
      case 'available': return (const Color(0xFF4CAF50), 'Available');
      case 'occupied': return (const Color(0xFFF44336), 'Occupied');
      case 'cleaning': return (const Color(0xFFFF9800), 'Cleaning');
      case 'maintenance': return (const Color(0xFF9E9E9E), 'Maintenance');
      case 'active': return (const Color(0xFF2196F3), 'Active');
      case 'checked_out': return (const Color(0xFF9E9E9E), 'Checked Out');
      case 'cancelled': return (const Color(0xFFF44336), 'Cancelled');
      case 'paid': return (const Color(0xFF4CAF50), 'Paid');
      case 'pending': return (const Color(0xFFFF9800), 'Pending');
      case 'partial': return (const Color(0xFF2196F3), 'Partial');
      case 'refunded': return (const Color(0xFF9C27B0), 'Refunded');
      default: return (const Color(0xFF9E9E9E), status);
    }
  }
}
