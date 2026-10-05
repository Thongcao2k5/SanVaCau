import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, this.baseUrl = ApiConfig.baseUrl})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$baseUrl$normalizedPath')
        .replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final response = await _httpClient.get(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(token),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _httpClient.post(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(token),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _httpClient.patch(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(token),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final response = await _httpClient.delete(
      _buildUri(path, queryParameters),
      headers: _buildHeaders(token),
    );

    return _decodeResponse(response);
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Invalid API response',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = decoded['message']?.toString() ?? 'Yêu cầu thất bại';

        if (response.statusCode == 401) {
          if (message.contains('invalid email or password')) {
            message = 'Email hoặc mật khẩu không chính xác';
          } else if (message.contains('current password is incorrect')) {
            message = 'Mật khẩu hiện tại không chính xác';
          } else {
            message = 'Phiên đăng nhập hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.';
          }
        } else if (response.statusCode == 403) {
          if (message.contains('account is not active')) {
            message = 'Tài khoản của bạn đã bị khóa hoặc chưa được kích hoạt.';
          } else if (message.toLowerCase().contains('forbidden')) {
            message = 'Bạn không có quyền thực hiện thao tác này.';
          }
        } else if (response.statusCode == 409) {
          if (message.contains('email already exists')) {
            message = 'Email đã được đăng ký, vui lòng sử dụng email khác.';
          }
        }

        throw ApiException(statusCode: response.statusCode, message: message);
      }

      return decoded;
    } on FormatException catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid JSON format',
      );
    }
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
