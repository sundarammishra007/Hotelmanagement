import 'package:flutter/material.dart';
import '../models/room_model.dart';
import 'status_badge.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final Function(String)? onStatusChange;

  const RoomCard({super.key, required this.room, this.onTap, this.onStatusChange});

  Color get _statusColor {
    switch (room.status) {
      case RoomStatus.available: return const Color(0xFF4CAF50);
      case RoomStatus.occupied: return const Color(0xFFF44336);
      case RoomStatus.cleaning: return const Color(0xFFFF9800);
      case RoomStatus.maintenance: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _statusColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room ${room.roomNumber}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            room.roomTypeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Floor ${room.floor}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                        const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Max ${room.maxOccupancy}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${room.pricePerNight.toStringAsFixed(0)}/night',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF5A623),
                          ),
                        ),
                        StatusBadge(status: room.status.name),
                      ],
                    ),
                  ],
                ),
              ),
              if (onStatusChange != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: DropdownButtonFormField<String>(
                    value: room.status.name,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: ['available', 'cleaning', 'maintenance']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) { if (v != null) onStatusChange!(v); },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
