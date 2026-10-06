import '../../../core/network/api_client.dart';
import '../models/branch_racket_service.dart';

class RacketServiceApi {
  RacketServiceApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<BranchRacketService>> getAvailableServices(
    String branchId,
  ) async {
    final response = await _apiClient.get('/branches/$branchId/services');
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['services'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(BranchRacketService.fromJson)
        .toList();
  }
}
