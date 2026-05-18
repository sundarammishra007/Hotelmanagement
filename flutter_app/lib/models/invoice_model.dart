import 'payment_model.dart';

enum PaymentStatus { pending, partial, paid, refunded }

class InvoiceModel {
  final String id;
  final String checkinId;
  final String invoiceNumber;
  final String guestId;
  final double roomCharges;
  final double extraCharges;
  final double discount;
  final double subtotal;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime? createdAt;
  // Joined fields
  final String? guestName;
  final String? guestPhone;
  final String? roomNumber;
  final String? roomType;
  final List<PaymentModel>? payments;

  const InvoiceModel({
    required this.id,
    required this.checkinId,
    required this.invoiceNumber,
    required this.guestId,
    required this.roomCharges,
    this.extraCharges = 0,
    this.discount = 0,
    required this.subtotal,
    this.cgstRate = 9,
    required this.cgstAmount,
    this.sgstRate = 9,
    required this.sgstAmount,
    required this.totalAmount,
    this.paymentStatus = PaymentStatus.pending,
    this.notes,
    this.createdAt,
    this.guestName,
    this.guestPhone,
    this.roomNumber,
    this.roomType,
    this.payments,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      checkinId: json['checkin_id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      guestId: json['guest_id']?.toString() ?? '',
      roomCharges: double.tryParse(json['room_charges']?.toString() ?? '0') ?? 0,
      extraCharges: double.tryParse(json['extra_charges']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      cgstRate: double.tryParse(json['cgst_rate']?.toString() ?? '9') ?? 9,
      cgstAmount: double.tryParse(json['cgst_amount']?.toString() ?? '0') ?? 0,
      sgstRate: double.tryParse(json['sgst_rate']?.toString() ?? '9') ?? 9,
      sgstAmount: double.tryParse(json['sgst_amount']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      paymentStatus: _parseStatus(json['payment_status']?.toString()),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      guestName: json['guest_name']?.toString(),
      guestPhone: json['guest_phone']?.toString(),
      roomNumber: json['room_number']?.toString(),
      roomType: json['room_type']?.toString(),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((p) => PaymentModel.fromJson(p))
          .toList(),
    );
  }

  static PaymentStatus _parseStatus(String? s) {
    switch (s) {
      case 'partial': return PaymentStatus.partial;
      case 'paid': return PaymentStatus.paid;
      case 'refunded': return PaymentStatus.refunded;
      default: return PaymentStatus.pending;
    }
  }

  String get statusLabel {
    switch (paymentStatus) {
      case PaymentStatus.pending: return 'Pending';
      case PaymentStatus.partial: return 'Partial';
      case PaymentStatus.paid: return 'Paid';
      case PaymentStatus.refunded: return 'Refunded';
    }
  }
}
