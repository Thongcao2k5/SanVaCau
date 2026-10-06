import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/support_ticket.dart';

class SupportApi {
  SupportApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String> _token() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để sử dụng hỗ trợ.',
      );
    }
    return token;
  }

  Future<List<SupportTicket>> getMyTickets() async {
    final response = await _apiClient.get(
      '/support/tickets/me',
      token: await _token(),
    );
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['tickets'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SupportTicket.fromJson)
        .toList();
  }

  Future<SupportTicket> getTicket(String id) async {
    final response = await _apiClient.get(
      '/support/tickets/$id',
      token: await _token(),
    );
    return _ticketFromResponse(response);
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
    required String category,
    required String priority,
  }) async {
    final response = await _apiClient.post(
      '/support/tickets',
      token: await _token(),
      body: {
        'subject': subject.trim(),
        'message': message.trim(),
        'category': category,
        'priority': priority,
      },
    );
    return _ticketFromResponse(response);
  }

  Future<SupportTicketMessage> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final response = await _apiClient.post(
      '/support/tickets/$ticketId/messages',
      token: await _token(),
      body: {'message': message.trim()},
    );
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final item = data['message'] as Map<String, dynamic>?;
    if (item == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu phản hồi không hợp lệ.',
      );
    }
    return SupportTicketMessage.fromJson(item);
  }

  SupportTicket _ticketFromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final item = data['ticket'] as Map<String, dynamic>?;
    if (item == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu yêu cầu hỗ trợ không hợp lệ.',
      );
    }
    return SupportTicket.fromJson(item);
  }
}
