import 'api_service.dart';
import '../config/api_config.dart';
import '../models/staff_model.dart';

class StaffService {
  final _api = ApiService();

  Future<List<StaffModel>> getStaff() async {
    final data = await _api.get(ApiConfig.staffEndpoint);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((j) => StaffModel.fromJson(j)).toList();
  }

  Future<StaffModel> getStaffById(String id) async {
    final data = await _api.get('${ApiConfig.staffEndpoint}/$id');
    return StaffModel.fromJson(data['data']);
  }

  Future<StaffModel> createStaff(Map<String, dynamic> body) async {
    final data = await _api.post(ApiConfig.staffEndpoint, body);
    return StaffModel.fromJson(data['data']);
  }

  Future<StaffModel> updateStaff(String id, Map<String, dynamic> body) async {
    final data = await _api.put('${ApiConfig.staffEndpoint}/$id', body);
    return StaffModel.fromJson(data['data']);
  }

  Future<Map<String, dynamic>> markAttendance(String staffId, Map<String, dynamic> body) async {
    final data = await _api.post('${ApiConfig.staffEndpoint}/$staffId/attendance', body);
    return data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<dynamic>> getAttendance(String staffId, {String? month}) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month;
    final data = await _api.get('${ApiConfig.staffEndpoint}/$staffId/attendance', queryParams: params);
    return data['data'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getTodayAttendance() async {
    final data = await _api.get('${ApiConfig.staffEndpoint}/attendance/today');
    return data['data'] as List<dynamic>? ?? [];
  }
}
