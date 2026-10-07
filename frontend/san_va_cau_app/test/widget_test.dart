import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/app.dart';

void main() {
  testWidgets('shows SanVaCau home page', (WidgetTester tester) async {
    await tester.pumpWidget(const SanVaCauApp());
    await tester.pump();

    // Consume the ApiException caused by the test environment's mocked HTTP client (which returns 400).
    tester.takeException();
    await tester.pump();

    expect(find.text('Sân & Cầu'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsWidgets);
    expect(find.text('Đặt sân'), findsWidgets);
    expect(find.text('Giỏ hàng'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}
