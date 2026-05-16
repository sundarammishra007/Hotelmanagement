import 'api_service.dart';
import '../config/api_config.dart';

class DashboardService {
  final _api = ApiService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await _api.get('${ApiConfig.dashboardEndpoint}/stats');
    return data['data'] as Map<String, dynamic>? ?? {};
  }
}
