import '../../../core/network/api_client.dart';
import '../models/app_status.dart';

class AppStatusApi {
  AppStatusApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AppStatus> getAppStatus(String platform, String version) async {
    final response = await _apiClient.get(
      '/app-status',
      queryParameters: {'platform': platform, 'version': version},
    );

    return AppStatus.fromJson(response['data'] as Map<String, dynamic>);
  }
}
