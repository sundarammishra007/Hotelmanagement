import 'api_service.dart';
import '../config/api_config.dart';
import '../models/checkin_model.dart';
import '../models/invoice_model.dart';

class CheckinService {
  final _api = ApiService();

  Future<List<CheckinModel>> getCheckins({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final data = await _api.get(ApiConfig.checkinsEndpoint, queryParams: params);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((j) => CheckinModel.fromJson(j)).toList();
  }

  Future<List<CheckinModel>> getActiveCheckins() async {
    final data = await _api.get('${ApiConfig.checkinsEndpoint}/active');
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((j) => CheckinModel.fromJson(j)).toList();
  }

  Future<CheckinModel> getCheckinById(String id) async {
    final data = await _api.get('${ApiConfig.checkinsEndpoint}/$id');
    return CheckinModel.fromJson(data['data']);
  }

  Future<CheckinModel> createCheckin(Map<String, dynamic> body) async {
    final data = await _api.post(ApiConfig.checkinsEndpoint, body);
    return CheckinModel.fromJson(data['data']);
  }

  Future<Map<String, dynamic>> checkOut(String id) async {
    final data = await _api.put('${ApiConfig.checkinsEndpoint}/$id/checkout', {});
    return data['data'] as Map<String, dynamic>;
  }
}
