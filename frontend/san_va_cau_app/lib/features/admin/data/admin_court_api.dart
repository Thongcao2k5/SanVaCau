import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../booking/models/court.dart';
import '../models/admin_court.dart';

class AdminCourtApi {
  AdminCourtApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<Court>> getCourts(String branchId) async {
    final response = await _apiClient.get(
      '/courts',
      queryParameters: {'branchId': branchId},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ((data['courts'] as List<dynamic>?) ?? const [])
        .map((item) => Court.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Court> createCourt({
    required String branchId,
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/courts',
      token: await _readToken(),
      body: {'branchId': branchId, 'name': name, 'description': description},
    );
    return Court.fromJson(response['data']['court'] as Map<String, dynamic>);
  }

  Future<Court> updateCourt({
    required String id,
    required String name,
    String? description,
    String? status,
  }) async {
    final response = await _apiClient.patch(
      '/courts/$id',
      token: await _readToken(),
      body: {'name': name, 'description': description, 'status': ?status},
    );
    return Court.fromJson(response['data']['court'] as Map<String, dynamic>);
  }

  Future<void> inactivateCourt(String id) async {
    await _apiClient.patch('/courts/$id/inactivate', token: await _readToken());
  }

  Future<List<AdminTimeSlot>> getTimeSlots() async {
    final response = await _apiClient.get('/courts/time-slots');
    final data = response['data'] as Map<String, dynamic>;
    return ((data['timeSlots'] as List<dynamic>?) ?? const [])
        .map((item) => AdminTimeSlot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminTimeSlot> createTimeSlot({
    required String startTime,
    required String endTime,
    required int sortOrder,
  }) async {
    final response = await _apiClient.post(
      '/courts/time-slots',
      token: await _readToken(),
      body: {
        'startTime': startTime,
        'endTime': endTime,
        'sortOrder': sortOrder,
      },
    );
    return AdminTimeSlot.fromJson(
      response['data']['timeSlot'] as Map<String, dynamic>,
    );
  }

  Future<AdminTimeSlot> updateTimeSlot({
    required String id,
    required String startTime,
    required String endTime,
    required int sortOrder,
    bool? isActive,
  }) async {
    final response = await _apiClient.patch(
      '/courts/time-slots/$id',
      token: await _readToken(),
      body: {
        'startTime': startTime,
        'endTime': endTime,
        'sortOrder': sortOrder,
        'isActive': ?isActive,
      },
    );
    return AdminTimeSlot.fromJson(
      response['data']['timeSlot'] as Map<String, dynamic>,
    );
  }

  Future<List<CourtPrice>> getCourtPrices(String courtId) async {
    final response = await _apiClient.get('/courts/$courtId/prices');
    final data = response['data'] as Map<String, dynamic>;
    return ((data['prices'] as List<dynamic>?) ?? const [])
        .map((item) => CourtPrice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourtPrice>> updateCourtPrices({
    required String courtId,
    required Map<String, double> prices,
  }) async {
    final response = await _apiClient.put(
      '/courts/$courtId/prices',
      token: await _readToken(),
      body: {
        'prices': [
          for (final entry in prices.entries)
            {'timeSlotId': entry.key, 'price': entry.value},
        ],
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return ((data['prices'] as List<dynamic>?) ?? const [])
        .map((item) => CourtPrice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> _readToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập đã hết hạn.',
      );
    }
    return token;
  }
}
