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

  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final session = await _saveSessionFromResponse(response);
    return session;
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
