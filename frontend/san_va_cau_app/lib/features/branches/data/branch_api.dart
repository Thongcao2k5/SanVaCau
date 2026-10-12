import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/branch.dart';

class BranchApi {
  BranchApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<Branch>> getBranches() async {
    final response = await _apiClient.get('/branches');
    final data = response['data'] as Map<String, dynamic>;
    final branchesJson = data['branches'] as List<dynamic>? ?? [];

    return branchesJson
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Branch> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    String? description,
    String? openingTime,
    String? closingTime,
    String? imageUrl,
    bool? isFeatured,
    int? sortOrder,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập đã hết hạn.',
      );
    }
    final response = await _apiClient.patch(
      '/branches/$id',
      token: token,
      body: {
        'name': ?name,
        'address': ?address,
        'phone': ?phone,
        'description': ?description,
        'openingTime': ?openingTime,
        'closingTime': ?closingTime,
        'imageUrl': ?imageUrl,
        'isFeatured': ?isFeatured,
        'sortOrder': ?sortOrder,
      },
    );
    return Branch.fromJson(response['data']['branch'] as Map<String, dynamic>);
  }

  Future<Branch> createBranch({
    required String name,
    required String address,
    required String openingTime,
    required String closingTime,
    String? phone,
    String? description,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập đã hết hạn.',
      );
    }
    final response = await _apiClient.post(
      '/branches',
      token: token,
      body: {
        'name': name,
        'address': address,
        'openingTime': openingTime,
        'closingTime': closingTime,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return Branch.fromJson(response['data']['branch'] as Map<String, dynamic>);
  }

  Future<void> inactivateBranch(String id) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập đã hết hạn.',
      );
    }
    await _apiClient.patch('/branches/$id/inactivate', token: token);
  }
}
