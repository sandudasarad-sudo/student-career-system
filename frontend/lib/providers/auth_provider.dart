import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  String? _token;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() => restoreSession();

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await _authService.getSavedToken();
      final savedUser = await _authService.getSavedUser();

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _user = savedUser;
        ApiService.setToken(savedToken);

        // Verify session freshness with server
        try {
          final freshUser = await _authService.getProfile();
          _user = freshUser;
        } catch (_) {
          // If server rejects token or is unreachable, handle accordingly
        }

        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);
      _token = result['token'] as String;
      _user = result['user'] as UserModel;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(name: name, email: email, password: password);
      // Auto-login after successful registration
      return await login(email, password);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearSession();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final freshUser = await _authService.getProfile();
      _user = freshUser;
      notifyListeners();
    } catch (_) {}
  }
}
