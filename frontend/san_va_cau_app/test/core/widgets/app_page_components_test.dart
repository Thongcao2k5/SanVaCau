import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/widgets/app_page_components.dart';

void main() {
  testWidgets('page intro and state view remain readable at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppPageIntro(
                    icon: Icons.favorite_border,
                    title: 'Nội dung đã lưu',
                    subtitle: 'Quản lý các sản phẩm yêu thích của bạn.',
                  ),
                  AppStateView(
                    icon: Icons.inbox_outlined,
                    title: 'Chưa có dữ liệu',
                    message: 'Nội dung sẽ xuất hiện tại đây.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Nội dung đã lưu'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
  });
}
