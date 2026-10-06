import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

String supportCategoryLabel(String value) => switch (value) {
  'ORDER' => 'Đơn hàng',
  'BOOKING' => 'Đặt sân',
  'PAYMENT' => 'Thanh toán',
  'ACCOUNT' => 'Tài khoản',
  _ => 'Khác',
};

String supportPriorityLabel(String value) => switch (value) {
  'LOW' => 'Thấp',
  'HIGH' => 'Cao',
  _ => 'Bình thường',
};

String supportStatusLabel(String value) => switch (value) {
  'IN_PROGRESS' => 'Đang xử lý',
  'RESOLVED' => 'Đã giải quyết',
  'CLOSED' => 'Đã đóng',
  _ => 'Mới gửi',
};

Color supportStatusColor(String value) => switch (value) {
  'IN_PROGRESS' => AppColors.warning,
  'RESOLVED' => AppColors.success,
  'CLOSED' => AppColors.textSecondary,
  _ => AppColors.primary,
};

String formatSupportDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)} ${two(local.day)}/${two(local.month)}/${local.year}';
}
