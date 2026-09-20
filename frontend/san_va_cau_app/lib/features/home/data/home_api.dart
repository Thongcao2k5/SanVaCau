import '../../../core/network/api_client.dart';
import '../models/home_data.dart';

class HomeApi {
  HomeApi([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<HomeData> getHomeData() async {
    final response = await _apiClient.get('/home');
    return HomeData.fromJson(response['data'] as Map<String, dynamic>);
  }
}
