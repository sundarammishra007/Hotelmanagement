enum PaymentMethod { cash, upi, card }

class PaymentModel {
  final String id;
  final String invoiceId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final DateTime? paidAt;
  final String? receivedBy;
  final String? notes;

  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    this.paidAt,
    this.receivedBy,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paymentMethod: _parseMethod(json['payment_method']?.toString()),
      transactionId: json['transaction_id']?.toString(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      receivedBy: json['received_by']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  static PaymentMethod _parseMethod(String? s) {
    switch (s) {
      case 'upi': return PaymentMethod.upi;
      case 'card': return PaymentMethod.card;
      default: return PaymentMethod.cash;
    }
  }

  String get methodLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.card: return 'Card';
    }
  }
}
