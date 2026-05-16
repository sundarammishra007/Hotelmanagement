import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool val) { _isLoading = val; notifyListeners(); }
  void _setError(String? err) { _error = err; notifyListeners(); }

  Future<bool> checkAuth() async {
    try {
      _setLoading(true);
      final token = await _authService.getToken();
      if (token == null) { _isLoggedIn = false; _setLoading(false); return false; }
      _currentUser = await _authService.getMe();
      _isLoggedIn = true;
      _setLoading(false);
      return true;
    } catch (_) {
      _isLoggedIn = false;
      await _authService.deleteToken();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      final data = await _authService.login(email, password);
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _isLoggedIn = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
