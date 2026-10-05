class ApiConfig {
  const ApiConfig._();

  // Android Emulator dùng 10.0.2.2 để gọi backend đang chạy trên máy tính.
  // Điện thoại thật dùng IP LAN của máy tính, ví dụ:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.40:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
}
