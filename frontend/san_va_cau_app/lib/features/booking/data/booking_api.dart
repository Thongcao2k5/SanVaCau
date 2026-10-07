import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/booking.dart';
import '../models/court.dart';

class BookingApi {
  BookingApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<Court>> getCourts({String? branchId}) async {
    final response = await _apiClient.get(
      '/courts',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    final data = response['data'] as Map<String, dynamic>;
    final courtsJson = data['courts'] as List<dynamic>? ?? [];

    return courtsJson
        .map((item) => Court.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourtPrice>> getCourtPrices(String courtId) async {
    final response = await _apiClient.get('/courts/$courtId/prices');
    final data = response['data'] as Map<String, dynamic>;
    final pricesJson = data['prices'] as List<dynamic>? ?? [];

    return pricesJson
        .map((item) => CourtPrice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingSlot>> getAvailability({
    required String courtId,
    required String date,
  }) async {
    final response = await _apiClient.get(
      '/bookings/availability',
      queryParameters: {'courtId': courtId, 'date': date},
    );
    final data = response['data'] as Map<String, dynamic>;
    final slotsJson = data['slots'] as List<dynamic>? ?? [];

    return slotsJson
        .map((item) => BookingSlot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createBooking({
    required String courtId,
    required String bookingDate,
    required List<String> timeSlotIds,
  }) async {
    final token = await _readToken();

    await _apiClient.post(
      '/bookings',
      token: token,
      body: {
        'courtId': courtId,
        'bookingDate': bookingDate,
        'timeSlotIds': timeSlotIds,
        'paymentMethod': 'CASH',
      },
    );
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _apiClient.get(
      '/bookings/me',
      token: await _readToken(),
    );
    final data = response['data'] as Map<String, dynamic>;
    final bookingsJson = data['bookings'] as List<dynamic>? ?? [];

    return bookingsJson
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelBooking(String id) async {
    await _apiClient.patch(
      '/bookings/$id/cancel',
      token: await _readToken(),
      body: {},
    );
  }

  Future<List<Booking>> getAdminBookings({
    String? branchId,
    String? courtId,
    String? date,
    String? status,
  }) async {
    final queryParameters = <String, String>{};
    if (branchId != null && branchId.trim().isNotEmpty) {
      queryParameters['branchId'] = branchId.trim();
    }
    if (courtId != null && courtId.trim().isNotEmpty) {
      queryParameters['courtId'] = courtId.trim();
    }
    if (date != null && date.trim().isNotEmpty) {
      queryParameters['date'] = date.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim().toUpperCase();
    }

    final response = await _apiClient.get(
      '/bookings',
      token: await _readToken(),
      queryParameters: queryParameters,
    );
    final data = response['data'] as Map<String, dynamic>;
    final bookingsJson = data['bookings'] as List<dynamic>? ?? [];

    return bookingsJson
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> updateAdminBookingStatus({
    required String id,
    required String status,
  }) async {
    final response = await _apiClient.patch(
      '/bookings/${id.trim()}/status',
      token: await _readToken(),
      body: {'status': status.trim().toUpperCase()},
    );

    // The updated booking is returned directly in data
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data);
  }

  Future<String> _readToken() async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    return token;
  }
}
