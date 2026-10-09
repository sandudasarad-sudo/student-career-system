import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConfig.register,
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    if (response is Map && response['user'] != null) {
      return UserModel.fromJson(response['user'] as Map<String, dynamic>);
    }
    throw ApiException('Registration succeeded, but user data was missing.');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConfig.login,
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );

    if (response is Map &&
        response['token'] != null &&
        response['user'] != null) {
      final token = response['token'].toString();
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      await saveSession(token, user);
      return {'token': token, 'user': user};
    }
    throw ApiException('Invalid server response format during login.');
  }

  Future<UserModel> getProfile() async {
    final response = await ApiService.get(ApiConfig.profile);
    if (response is Map && response['user'] != null) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      // Refresh local user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
      return user;
    }
    throw ApiException('Failed to retrieve user profile.');
  }

  Future<void> saveSession(String token, UserModel user) async {
    ApiService.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
      return token;
    }
    return null;
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString(_keyUser);
    if (userJsonStr != null && userJsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJsonStr);
        return UserModel.fromJson(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearSession() async {
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
