class ApiConfig {
  const ApiConfig._();

  // Android Emulator dùng 10.0.2.2 để gọi backend đang chạy trên máy tính.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
}
