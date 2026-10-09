import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => message;
}

class ApiService {
  static String? _authToken;

  static void setToken(String? token) {
    _authToken = token;
  }

  static String? get token => _authToken;

  static Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {
        'message': response.body.isNotEmpty
            ? response.body
            : 'Unknown server response',
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMsg = 'An error occurred';
    if (body is Map && body.containsKey('message')) {
      errorMsg = body['message'].toString();
    } else if (body is Map && body.containsKey('error')) {
      errorMsg = body['error'].toString();
    } else if (response.statusCode == 401) {
      errorMsg = 'Session expired or unauthorized. Please login.';
    } else if (response.statusCode == 403) {
      errorMsg = 'Access denied. You do not have permission.';
    } else if (response.statusCode == 404) {
      errorMsg = 'Resource not found.';
    } else if (response.statusCode == 409) {
      errorMsg = 'Conflict or duplicate entry.';
    } else if (response.statusCode >= 500) {
      errorMsg = 'Server error. Please try again later.';
    }

    throw ApiException(errorMsg, response.statusCode);
  }

  static Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _buildHeaders(extraHeaders: headers))
          .timeout(ApiConfig.timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Check your network or server status.',
        0,
      );
    } on http.ClientException {
      throw ApiException(
        'Network connection failed. Please check your connection.',
        0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  static Future<dynamic> post(
    String url, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _buildHeaders(extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Check your network or server status.',
        0,
      );
    } on http.ClientException {
      throw ApiException(
        'Network connection failed. Please check your connection.',
        0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  static Future<dynamic> put(
    String url, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _buildHeaders(extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Check your network or server status.',
        0,
      );
    } on http.ClientException {
      throw ApiException(
        'Network connection failed. Please check your connection.',
        0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  static Future<dynamic> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _buildHeaders(extraHeaders: headers))
          .timeout(ApiConfig.timeoutDuration);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Check your network or server status.',
        0,
      );
    } on http.ClientException {
      throw ApiException(
        'Network connection failed. Please check your connection.',
        0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
