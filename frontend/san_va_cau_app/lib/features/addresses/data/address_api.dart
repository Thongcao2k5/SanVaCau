import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/customer_address.dart';

class AddressApi {
  AddressApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String> _token() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để quản lý địa chỉ.',
      );
    }
    return token;
  }

  Future<List<CustomerAddress>> getAddresses() async {
    final response = await _apiClient.get('/addresses', token: await _token());
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['addresses'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CustomerAddress.fromJson)
        .toList();
  }

  Future<CustomerAddress> createAddress({
    required String recipientName,
    required String phone,
    required String addressLine,
    String? ward,
    String? district,
    String? city,
    String? note,
    bool isDefault = false,
  }) async {
    final response = await _apiClient.post(
      '/addresses',
      token: await _token(),
      body: _addressBody(
        recipientName: recipientName,
        phone: phone,
        addressLine: addressLine,
        ward: ward,
        district: district,
        city: city,
        note: note,
        isDefault: isDefault,
      ),
    );
    return _addressFromResponse(response);
  }

  Future<CustomerAddress> updateAddress({
    required String id,
    required String recipientName,
    required String phone,
    required String addressLine,
    String? ward,
    String? district,
    String? city,
    String? note,
    required bool isDefault,
  }) async {
    final response = await _apiClient.patch(
      '/addresses/$id',
      token: await _token(),
      body: _addressBody(
        recipientName: recipientName,
        phone: phone,
        addressLine: addressLine,
        ward: ward,
        district: district,
        city: city,
        note: note,
        isDefault: isDefault,
      ),
    );
    return _addressFromResponse(response);
  }

  Future<CustomerAddress> setDefault(String id) async {
    final response = await _apiClient.patch(
      '/addresses/$id/default',
      token: await _token(),
    );
    return _addressFromResponse(response);
  }

  Future<void> deleteAddress(String id) async {
    await _apiClient.delete('/addresses/$id', token: await _token());
  }

  Map<String, dynamic> _addressBody({
    required String recipientName,
    required String phone,
    required String addressLine,
    String? ward,
    String? district,
    String? city,
    String? note,
    required bool isDefault,
  }) {
    return {
      'recipientName': recipientName.trim(),
      'phone': phone.trim(),
      'addressLine': addressLine.trim(),
      'ward': ward?.trim(),
      'district': district?.trim(),
      'city': city?.trim(),
      'note': note?.trim(),
      'isDefault': isDefault,
    };
  }

  CustomerAddress _addressFromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu địa chỉ không hợp lệ.',
      );
    }
    return CustomerAddress.fromJson(address);
  }
}
