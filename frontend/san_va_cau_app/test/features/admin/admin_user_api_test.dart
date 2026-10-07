import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/admin/data/admin_user_api.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token = 'fake_token']);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}

class FakeApiClient extends ApiClient {
  String? lastMethod;
  String? lastPath;
  Map<String, String>? lastQuery;
  Map<String, dynamic>? lastBody;
  String? lastToken;
  bool shouldThrow = false;
  ApiException? exceptionToThrow;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = queryParameters;
    lastToken = token;

    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Error');
    }

    return {
      'data': {
        'users': [
          {
            'id': '1',
            'email': 'staff@example.com',
            'fullName': 'Staff Name',
            'role': 'STAFF',
            'status': 'ACTIVE',
            'branchId': '2',
            'mustChangePassword': true,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    lastToken = token;

    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (shouldThrow) {
      throw const ApiException(statusCode: 409, message: 'Conflict');
    }

    return {
      'data': {
        'user': {
          'id': 'new',
          'email': body?['email'],
          'fullName': body?['fullName'],
          'role': body?['role'],
          'status': 'ACTIVE',
          'branchId': body?['branchId'],
          'mustChangePassword': true,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastBody = body;
    lastToken = token;

    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (shouldThrow) {
      throw const ApiException(statusCode: 400, message: 'Bad Request');
    }

    if (path.endsWith('/status')) {
      return {
        'data': {
          'user': {
            'id': '1',
            'email': 'staff@example.com',
            'fullName': 'Staff Name',
            'role': 'STAFF',
            'status': body?['status'],
            'mustChangePassword': true,
          },
        },
      };
    }

    if (path.endsWith('/password')) {
      return {
        'data': {
          'user': {'id': '1'},
        },
      };
    }

    return {};
  }
}

void main() {
  group('AdminUserApi Tests', () {
    late AdminUserApi api;
    late FakeApiClient apiClient;

    setUp(() {
      apiClient = FakeApiClient();
      api = AdminUserApi(
        apiClient: apiClient,
        tokenStorage: FakeTokenStorage(),
      );
    });

    test('getUsers parses correctly', () async {
      final users = await api.getUsers(page: 1, limit: 50);
      expect(users.length, 1);
      expect(users.first.id, '1');
      expect(users.first.role, 'STAFF');
      expect(users.first.mustChangePassword, true);

      expect(apiClient.lastMethod, 'GET');
      expect(apiClient.lastPath, '/auth/admin/users');
      expect(apiClient.lastQuery?['page'], '1');
      expect(apiClient.lastQuery?['limit'], '50');
      expect(apiClient.lastToken, 'fake_token');
    });

    test('createUser sends correct body', () async {
      final user = await api.createUser(
        email: 'test@example.com',
        password: 'password123',
        fullName: 'Test User',
        role: 'BRANCH_MANAGER',
        branchId: 'b1',
      );

      expect(user.id, 'new');
      expect(user.email, 'test@example.com');

      expect(apiClient.lastMethod, 'POST');
      expect(apiClient.lastPath, '/auth/admin/users');
      expect(apiClient.lastBody?['email'], 'test@example.com');
      expect(apiClient.lastBody?['password'], 'password123');
      expect(apiClient.lastBody?['fullName'], 'Test User');
      expect(apiClient.lastBody?['phone'], isNull);
      expect(apiClient.lastBody?['role'], 'BRANCH_MANAGER');
      expect(apiClient.lastBody?['branchId'], 'b1');
      expect(apiClient.lastToken, 'fake_token');
    });

    test('updateUserStatus sends correct payload', () async {
      final user = await api.updateUserStatus(userId: 'u1', status: 'LOCKED');
      expect(user.status, 'LOCKED');

      expect(apiClient.lastMethod, 'PATCH');
      expect(apiClient.lastPath, '/auth/admin/users/u1/status');
      expect(apiClient.lastBody?['status'], 'LOCKED');
      expect(apiClient.lastToken, 'fake_token');
    });

    test('resetUserPassword sends correct payload', () async {
      await api.resetUserPassword(userId: 'u2', newPassword: 'new-password');

      expect(apiClient.lastMethod, 'PATCH');
      expect(apiClient.lastPath, '/auth/admin/users/u2/password');
      expect(apiClient.lastBody?['newPassword'], 'new-password');
      expect(apiClient.lastToken, 'fake_token');
    });

    test('all operations reject a missing token before calling HTTP', () async {
      final missingTokenApi = AdminUserApi(
        apiClient: apiClient,
        tokenStorage: FakeTokenStorage(null),
      );

      final operations = <Future<void> Function()>[
        () async {
          await missingTokenApi.getUsers();
        },
        () async {
          await missingTokenApi.createUser(
            email: 'staff@example.com',
            password: 'Password123',
            fullName: 'Staff',
            role: 'STAFF',
            branchId: '1',
          );
        },
        () async {
          await missingTokenApi.updateUserStatus(userId: '1', status: 'LOCKED');
        },
        () async {
          await missingTokenApi.resetUserPassword(
            userId: '1',
            newPassword: 'Password456',
          );
        },
      ];

      for (final operation in operations) {
        await expectLater(
          operation(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.message, 'message', 'Unauthorized'),
          ),
        );
      }
      expect(apiClient.lastMethod, isNull);
    });

    test('403, 404, and 409 ApiExceptions propagate unchanged', () async {
      Future<void> expectPropagation(
        ApiException exception,
        Future<void> Function() operation,
      ) async {
        apiClient.exceptionToThrow = exception;
        await expectLater(
          operation(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', exception.statusCode)
                .having((e) => e.message, 'message', exception.message),
          ),
        );
      }

      await expectPropagation(
        const ApiException(statusCode: 403, message: 'Forbidden'),
        () async {
          await api.getUsers();
        },
      );
      await expectPropagation(
        const ApiException(statusCode: 404, message: 'User not found'),
        () async {
          await api.updateUserStatus(userId: '404', status: 'LOCKED');
        },
      );
      await expectPropagation(
        const ApiException(statusCode: 409, message: 'Email exists'),
        () async {
          await api.createUser(
            email: 'duplicate@example.com',
            password: 'Password123',
            fullName: 'Duplicate',
            role: 'STAFF',
            branchId: '1',
          );
        },
      );
    });

    test('Exceptions propagate correctly', () async {
      apiClient.shouldThrow = true;
      expect(() => api.getUsers(), throwsA(isA<ApiException>()));
      expect(
        () => api.createUser(
          email: '',
          password: '',
          fullName: '',
          role: '',
          branchId: '',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => api.updateUserStatus(userId: '', status: ''),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => api.resetUserPassword(userId: '', newPassword: ''),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
