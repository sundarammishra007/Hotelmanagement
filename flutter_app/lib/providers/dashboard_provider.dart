import 'package:flutter/foundation.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final _service = DashboardService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> fetchStats() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _stats = await _service.getDashboardStats();
      _lastUpdated = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchStats();
}
