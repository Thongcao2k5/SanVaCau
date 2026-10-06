import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/help/data/help_api.dart';
import 'package:san_va_cau_app/features/help/models/help_content.dart';
import 'package:san_va_cau_app/features/help/pages/help_center_page.dart';

class _FakeHelpApi extends HelpApi {
  @override
  Future<HelpContent> getHelpContent() async => const HelpContent(
    faqs: [
      FaqItem(
        id: '1',
        category: 'Đặt sân',
        question: 'Làm sao để đặt sân?',
        answer: 'Chọn sân và khung giờ.',
      ),
      FaqItem(
        id: '2',
        category: 'Mua hàng',
        question: 'Làm sao để mua vợt?',
        answer: 'Thêm sản phẩm vào giỏ hàng.',
      ),
    ],
    pages: [],
  );
}

void main() {
  testWidgets('filters FAQ items locally by their category', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HelpCenterPage(helpApi: _FakeHelpApi())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Làm sao để đặt sân?'), findsOneWidget);
    expect(find.text('Làm sao để mua vợt?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Đặt sân'));
    await tester.pumpAndSettle();

    expect(find.text('Làm sao để đặt sân?'), findsOneWidget);
    expect(find.text('Làm sao để mua vợt?'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.pumpAndSettle();

    expect(find.text('Làm sao để đặt sân?'), findsOneWidget);
    expect(find.text('Làm sao để mua vợt?'), findsOneWidget);
  });
}
