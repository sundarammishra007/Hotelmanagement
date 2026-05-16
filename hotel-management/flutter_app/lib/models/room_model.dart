enum RoomStatus { available, occupied, cleaning, maintenance }
enum RoomType { single, double_, suite, deluxe }

class RoomModel {
  final String id;
  final String roomNumber;
  final int floor;
  final RoomType roomType;
  final RoomStatus status;
  final double pricePerNight;
  final List<String> amenities;
  final String? description;
  final int maxOccupancy;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.status,
    required this.pricePerNight,
    this.amenities = const [],
    this.description,
    this.maxOccupancy = 2,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      roomNumber: json['room_number']?.toString() ?? '',
      floor: int.tryParse(json['floor']?.toString() ?? '1') ?? 1,
      roomType: _parseRoomType(json['room_type']?.toString()),
      status: _parseStatus(json['status']?.toString()),
      pricePerNight: double.tryParse(json['price_per_night']?.toString() ?? '0') ?? 0,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description']?.toString(),
      maxOccupancy: int.tryParse(json['max_occupancy']?.toString() ?? '2') ?? 2,
    );
  }

  static RoomStatus _parseStatus(String? s) {
    switch (s) {
      case 'occupied': return RoomStatus.occupied;
      case 'cleaning': return RoomStatus.cleaning;
      case 'maintenance': return RoomStatus.maintenance;
      default: return RoomStatus.available;
    }
  }

  static RoomType _parseRoomType(String? s) {
    switch (s) {
      case 'double': return RoomType.double_;
      case 'suite': return RoomType.suite;
      case 'deluxe': return RoomType.deluxe;
      default: return RoomType.single;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_number': roomNumber,
        'floor': floor,
        'room_type': roomType.name == 'double_' ? 'double' : roomType.name,
        'status': status.name,
        'price_per_night': pricePerNight,
        'amenities': amenities,
        'description': description,
        'max_occupancy': maxOccupancy,
      };

  String get statusLabel {
    switch (status) {
      case RoomStatus.available: return 'Available';
      case RoomStatus.occupied: return 'Occupied';
      case RoomStatus.cleaning: return 'Cleaning';
      case RoomStatus.maintenance: return 'Maintenance';
    }
  }

  String get roomTypeLabel {
    switch (roomType) {
      case RoomType.single: return 'Single';
      case RoomType.double_: return 'Double';
      case RoomType.suite: return 'Suite';
      case RoomType.deluxe: return 'Deluxe';
    }
  }
}
