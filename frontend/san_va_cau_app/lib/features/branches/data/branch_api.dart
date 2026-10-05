import '../../../core/network/api_client.dart';
import '../models/branch.dart';

class BranchApi {
  BranchApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Branch>> getBranches() async {
    final response = await _apiClient.get('/branches');
    final data = response['data'] as Map<String, dynamic>;
    final branchesJson = data['branches'] as List<dynamic>? ?? [];

    return branchesJson
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
