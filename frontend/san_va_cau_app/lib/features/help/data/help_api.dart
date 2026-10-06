import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/help_content.dart';

class HelpApi {
  HelpApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<FaqItem>> getFaqs() async {
    final response = await _apiClient.get(
      '/faqs',
      queryParameters: const {'page': '1', 'limit': '100'},
    );
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['faqs'] as List<dynamic>? ?? const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(FaqItem.fromJson)
        .toList();
  }

  Future<List<StaticPageSummary>> getPages() async {
    final response = await _apiClient.get(
      '/pages',
      queryParameters: const {'page': '1', 'limit': '100'},
    );
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['pages'] as List<dynamic>? ?? const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(StaticPageSummary.fromJson)
        .where((page) => page.slug.isNotEmpty && page.title.isNotEmpty)
        .toList();
  }

  Future<HelpContent> getHelpContent() async {
    final results = await Future.wait([getFaqs(), getPages()]);
    return HelpContent(
      faqs: results[0] as List<FaqItem>,
      pages: results[1] as List<StaticPageSummary>,
    );
  }

  Future<StaticPageDetail> getPageBySlug(String slug) async {
    final response = await _apiClient.get('/pages/$slug');
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return StaticPageDetail.fromJson(data);
  }

  Future<void> submitContact({
    required String fullName,
    required String type,
    required String subject,
    required String message,
    String? email,
    String? phone,
  }) async {
    final token = await _tokenStorage.readToken();
    await _apiClient.post(
      '/contact',
      token: token,
      body: {
        'fullName': fullName.trim(),
        'type': type,
        'subject': subject.trim(),
        'message': message.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }
}
