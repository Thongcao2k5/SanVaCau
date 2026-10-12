import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../constants/api_config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl,
      _httpClient = httpClient ?? http.Client();

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

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _httpClient.put(
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

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String filePath,
    String fieldName = 'image',
    String? token,
  }) async {
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    const allowedImageTypes = {'image/jpeg', 'image/png', 'image/webp'};

    if (!allowedImageTypes.contains(mimeType)) {
      throw const ApiException(
        statusCode: 400,
        message: 'Định dạng ảnh không được hỗ trợ. Vui lòng chọn ảnh JPEG, PNG hoặc WebP.',
      );
    }

    final request = http.MultipartRequest('POST', _buildUri(path));
    request.headers.addAll(_buildHeaders(token)..remove('Content-Type'));
    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        contentType: MediaType.parse(mimeType),
      ),
    );
    final streamedResponse = await _httpClient.send(request);
    return _decodeResponse(await http.Response.fromStream(streamedResponse));
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

        if (response.statusCode == 400) {
          if (message.contains('email is invalid')) {
            message = 'Email không đúng định dạng';
          } else if (message.contains('registration data is invalid')) {
            message = 'Thông tin đăng ký không hợp lệ';
          } else if (message.contains('OTP is invalid or expired')) {
            message = 'Mã OTP không đúng hoặc đã hết hạn';
          } else if (message.contains('reset data is invalid')) {
            message = 'Thông tin đặt lại mật khẩu không hợp lệ';
          } else if (message.contains(
            'new password must be different from current password',
          )) {
            message = 'Mật khẩu mới phải khác mật khẩu hiện tại';
          } else if (message.contains('Invalid file type')) {
            message = 'Định dạng ảnh không được hỗ trợ. Vui lòng chọn ảnh JPEG, PNG hoặc WebP.';
          } else if (message.contains('File is too large')) {
            message = 'Ảnh vượt quá 5 MB. Vui lòng chọn ảnh nhỏ hơn.';
          } else if (message.contains('No image file provided')) {
            message = 'Không tìm thấy ảnh để tải lên.';
          }
        } else if (response.statusCode == 401) {
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
        } else if (response.statusCode == 429) {
          message = 'Vui lòng chờ trước khi yêu cầu gửi lại mã OTP.';
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
