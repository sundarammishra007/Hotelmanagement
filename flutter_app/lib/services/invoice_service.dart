import 'api_service.dart';
import '../config/api_config.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final _api = ApiService();

  Future<List<InvoiceModel>> getInvoices({String? paymentStatus}) async {
    final params = <String, String>{};
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    final data = await _api.get(ApiConfig.invoicesEndpoint, queryParams: params);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((j) => InvoiceModel.fromJson(j)).toList();
  }

  Future<InvoiceModel> getInvoiceById(String id) async {
    final data = await _api.get('${ApiConfig.invoicesEndpoint}/$id');
    return InvoiceModel.fromJson(data['data']);
  }

  Future<InvoiceModel> getInvoiceByCheckinId(String checkinId) async {
    final data = await _api.get('${ApiConfig.invoicesEndpoint}/checkin/$checkinId');
    return InvoiceModel.fromJson(data['data']);
  }

  Future<InvoiceModel> generateInvoice(String checkinId, {double extraCharges = 0, double discount = 0}) async {
    final data = await _api.post('${ApiConfig.invoicesEndpoint}/generate', {
      'checkin_id': checkinId,
      'extra_charges': extraCharges,
      'discount': discount,
    });
    return InvoiceModel.fromJson(data['data']);
  }

  Future<InvoiceModel> updateInvoice(String id, Map<String, dynamic> body) async {
    final data = await _api.put('${ApiConfig.invoicesEndpoint}/$id', body);
    return InvoiceModel.fromJson(data['data']);
  }

  Future<InvoiceModel> addPayment(String invoiceId, Map<String, dynamic> body) async {
    final data = await _api.post('${ApiConfig.invoicesEndpoint}/$invoiceId/payment', body);
    return InvoiceModel.fromJson(data['data']);
  }

  Future<List<int>> downloadInvoicePDF(String invoiceId) async {
    return _api.getBytes('${ApiConfig.invoicesEndpoint}/$invoiceId/download');
  }
}
