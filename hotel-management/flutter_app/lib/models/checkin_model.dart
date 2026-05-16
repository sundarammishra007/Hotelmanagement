import 'guest_model.dart';
import 'room_model.dart';

enum CheckinStatus { active, checked_out, cancelled }

class CheckinModel {
  final String id;
  final String guestId;
  final String roomId;
  final String? checkedInBy;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final DateTime? actualCheckout;
  final int adults;
  final int children;
  final String? specialRequests;
  final CheckinStatus status;
  // Joined fields
  final String? guestName;
  final String? guestPhone;
  final String? guestEmail;
  final String? roomNumber;
  final String? roomType;
  final int? floor;
  final double? pricePerNight;
  final GuestModel? guest;
  final RoomModel? room;

  const CheckinModel({
    required this.id,
    required this.guestId,
    required this.roomId,
    this.checkedInBy,
    required this.checkInDate,
    this.checkOutDate,
    this.actualCheckout,
    this.adults = 1,
    this.children = 0,
    this.specialRequests,
    this.status = CheckinStatus.active,
    this.guestName,
    this.guestPhone,
    this.guestEmail,
    this.roomNumber,
    this.roomType,
    this.floor,
    this.pricePerNight,
    this.guest,
    this.room,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id']?.toString() ?? '',
      guestId: json['guest_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      checkedInBy: json['checked_in_by']?.toString(),
      checkInDate: DateTime.parse(json['check_in_date'].toString()),
      checkOutDate: json['check_out_date'] != null
          ? DateTime.tryParse(json['check_out_date'].toString())
          : null,
      actualCheckout: json['actual_checkout'] != null
          ? DateTime.tryParse(json['actual_checkout'].toString())
          : null,
      adults: int.tryParse(json['adults']?.toString() ?? '1') ?? 1,
      children: int.tryParse(json['children']?.toString() ?? '0') ?? 0,
      specialRequests: json['special_requests']?.toString(),
      status: _parseStatus(json['status']?.toString()),
      guestName: json['guest_name']?.toString(),
      guestPhone: json['guest_phone']?.toString(),
      guestEmail: json['guest_email']?.toString(),
      roomNumber: json['room_number']?.toString(),
      roomType: json['room_type']?.toString(),
      floor: int.tryParse(json['floor']?.toString() ?? ''),
      pricePerNight: double.tryParse(json['price_per_night']?.toString() ?? ''),
      guest: json['guest'] != null ? GuestModel.fromJson(json['guest']) : null,
      room: json['room'] != null ? RoomModel.fromJson(json['room']) : null,
    );
  }

  static CheckinStatus _parseStatus(String? s) {
    switch (s) {
      case 'checked_out': return CheckinStatus.checked_out;
      case 'cancelled': return CheckinStatus.cancelled;
      default: return CheckinStatus.active;
    }
  }

  int get nights {
    final end = actualCheckout ?? checkOutDate ?? DateTime.now();
    return (end.difference(checkInDate).inHours / 24).ceil().clamp(1, 999);
  }

  String get statusLabel {
    switch (status) {
      case CheckinStatus.active: return 'Active';
      case CheckinStatus.checked_out: return 'Checked Out';
      case CheckinStatus.cancelled: return 'Cancelled';
    }
  }
}
