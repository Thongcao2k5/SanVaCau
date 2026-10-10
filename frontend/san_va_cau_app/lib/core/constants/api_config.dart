import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  const ApiConfig._();

  /// Địa chỉ IP máy tính cá nhân trong mạng LAN sử dụng cho thiết bị thật (Android/iOS)
  static const String pcIp = String.fromEnvironment(
    'PC_IP',
    defaultValue: '172.16.0.209',
  );

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';

    // Cờ xác định khi chạy trên thiết bị thật (Android/iOS)
    const bool isPhysicalDevice = bool.fromEnvironment(
      'IS_PHYSICAL_DEVICE',
      defaultValue: false,
    );
    const bool usePcIp = bool.fromEnvironment('USE_PC_IP', defaultValue: false);

    if (isPhysicalDevice || usePcIp) {
      return 'http://$pcIp:3000/api';
    }

    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
      if (Platform.isIOS) return 'http://localhost:3000/api';
    } catch (_) {
      // Platform check fails on web if dart:io is used, nhưng kIsWeb đã xử lý trước đó
    }
    return 'http://localhost:3000/api';
  }

  // - Android Emulator dùng 10.0.2.2 để gọi backend đang chạy trên máy tính.
  // - Web / iOS Simulator dùng localhost.
  // - Thiết bị thật Android/iOS dùng IP LAN của máy tính cá nhân (mặc định: 172.16.0.209).
  //
  // Các cách truyền tham số khi chạy:
  // 1. Chạy thiết bị thật dùng IP cá nhân 172.16.0.209:
  //    flutter run --dart-define=IS_PHYSICAL_DEVICE=true
  // 2. Chạy thiết bị thật với IP tùy chỉnh:
  //    flutter run --dart-define=IS_PHYSICAL_DEVICE=true --dart-define=PC_IP=172.16.0.209
  // 3. Đặt trực tiếp URL API đầy đủ:
  //    flutter run --dart-define=API_BASE_URL=http://172.16.0.209:3000/api
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return defaultBaseUrl;
  }

  static String resolveMediaUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final apiUri = Uri.parse(baseUrl);
    final origin = apiUri.replace(path: '', query: null, fragment: null);
    return origin.resolve(value).toString();
  }
}
