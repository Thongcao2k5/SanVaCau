import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/main/main_shell.dart';

class _GuestAuthApi extends AuthApi {
  @override
  Future<AuthUser> getProfile() async {
    throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
  }

  @override
  Future<void> logout() async {}
}

class _EmptyCartApi extends CartApi {
  @override
  Future<Cart> getCart() async {
    return const Cart(
      id: 'cart',
      customerId: 'guest',
      items: [],
      totalAmount: 0,
    );
  }
}

void main() {
  testWidgets('shows SanVaCau home page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(authApi: _GuestAuthApi(), cartApi: _EmptyCartApi()),
      ),
    );
    await tester.pump();

    expect(find.text('Sân & Cầu'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsWidgets);
    expect(find.text('Đặt sân'), findsWidgets);
    expect(find.text('Giỏ hàng'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}
