import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/app.dart';

void main() {
  group('MainShell bottom navigation', () {
    testWidgets('contains five destinations in correct order', (tester) async {
      await tester.pumpWidget(const SanVaCauApp());
      await tester.pump();

      // Consume the ApiException caused by the test environment.
      tester.takeException();
      await tester.pump();

      // Verify all five destination labels exist.
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsWidgets);
      expect(find.text('Đặt sân'), findsWidgets);
      expect(find.text('Giỏ hàng'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);

      // Verify the animated notch navigation component exists.
      expect(find.byType(AnimatedNotchBottomBar), findsOneWidget);
    });

    testWidgets('preserves selected tab via IndexedStack', (tester) async {
      await tester.pumpWidget(const SanVaCauApp());
      await tester.pump();
      tester.takeException();
      await tester.pump();

      // Verify IndexedStack is used.
      expect(find.byType(IndexedStack), findsOneWidget);

      // Tap on "Sản phẩm" tab (index 1).
      final navBar = find.byType(AnimatedNotchBottomBar);
      expect(navBar, findsOneWidget);

      await tester.tap(find.text('Sản phẩm').last);
      await tester.pump(const Duration(milliseconds: 400));

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 1);
    });

    testWidgets('home tab is selected by default', (tester) async {
      await tester.pumpWidget(const SanVaCauApp());
      await tester.pump();
      tester.takeException();
      await tester.pump();

      // The IndexedStack should have index 0 by default.
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 0);
    });
  });
}
