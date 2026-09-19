import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/app.dart';

void main() {
  testWidgets('shows SanVaCau home page', (WidgetTester tester) async {
    await tester.pumpWidget(const SanVaCauApp());

    expect(find.text('SanVaCau'), findsOneWidget);
    expect(find.text('SanVaCau App'), findsOneWidget);
    expect(
      find.text('Đặt sân nhanh,\nmua đồ cầu lông dễ dàng'),
      findsOneWidget,
    );
    expect(find.text('Sản phẩm'), findsWidgets);
    expect(find.text('Đặt sân'), findsWidgets);
  });
}
