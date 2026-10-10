import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_user.dart';

class AuthApi {
  AuthApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    final session = await _saveSessionFromResponse(response);
    return session;
  }

  Future<OtpRequestResult> requestRegistrationOtp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      '/auth/register/request-otp',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    return OtpRequestResult.fromResponse(response);
  }

  Future<AuthSession> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.post(
      '/auth/register/verify-otp',
      body: {'email': email, 'code': code},
    );
    return _saveSessionFromResponse(response);
  }

  Future<OtpRequestResult> requestPasswordResetOtp(String email) async {
    final response = await _apiClient.post(
      '/auth/forgot-password/request-otp',
      body: {'email': email},
    );
    return OtpRequestResult.fromResponse(response);
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.post(
      '/auth/forgot-password/verify-otp',
      body: {'email': email, 'code': code},
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['resetToken']?.toString() ?? '';
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/auth/forgot-password/reset',
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }

  Future<OtpRequestResult> requestEmailChangeOtp(String newEmail) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    final response = await _apiClient.post(
      '/auth/email-change/request-otp',
      token: token,
      body: {'newEmail': newEmail},
    );
    return OtpRequestResult.fromResponse(response);
  }

  Future<AuthUser> verifyEmailChangeOtp({
    required String newEmail,
    required String code,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    final response = await _apiClient.post(
      '/auth/email-change/verify-otp',
      token: token,
      body: {'newEmail': newEmail, 'code': code},
    );
    final data = response['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> getProfile() async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    final response = await _apiClient.get('/auth/profile', token: token);
    final data = response['data'] as Map<String, dynamic>;

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }

  Future<AuthUser> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    final response = await _apiClient.patch(
      '/auth/profile',
      token: token,
      body: {'fullName': fullName, 'phone': phone},
    );

    final data = response['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(String filePath) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    final response = await _apiClient.postMultipart(
      '/uploads/avatar',
      token: token,
      filePath: filePath,
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['avatarUrl']?.toString() ?? '';
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    await _apiClient.post(
      '/auth/change-password',
      token: token,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<AuthSession> _saveSessionFromResponse(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

    await _tokenStorage.saveToken(token);

    return AuthSession(user: user, token: token);
  }
}

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AuthUser user;
  final String token;
}

class OtpRequestResult {
  const OtpRequestResult({
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  factory OtpRequestResult.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return OtpRequestResult(
      expiresInSeconds: (data['expiresInSeconds'] as num?)?.toInt() ?? 300,
      resendAfterSeconds: (data['resendAfterSeconds'] as num?)?.toInt() ?? 60,
    );
  }

  final int expiresInSeconds;
  final int resendAfterSeconds;
}
