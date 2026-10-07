import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';
import 'package:san_va_cau_app/features/home/widgets/home_quick_actions.dart';

void main() {
  Widget buildTestApp({
    VoidCallback? onBookCourt,
    VoidCallback? onViewProducts,
    VoidCallback? onRacketService,
    VoidCallback? onViewBranches,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: HomeQuickActions(
          onBookCourtPressed: onBookCourt ?? () {},
          onViewProductsPressed: onViewProducts ?? () {},
          onRacketServicePressed: onRacketService ?? () {},
          onViewBranchesPressed: onViewBranches ?? () {},
        ),
      ),
    );
  }

  group('HomeQuickActions', () {
    testWidgets('shows exactly four quick actions', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Đặt sân'), findsOneWidget);
      expect(find.text('Mua sắm'), findsOneWidget);
      expect(find.text('Dịch vụ\nvợt'), findsOneWidget);
      expect(find.text('Chi nhánh'), findsOneWidget);
    });

    testWidgets('shows heading Khám phá nhanh', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Khám phá nhanh'), findsOneWidget);
    });

    testWidgets('Đặt sân calls onBookCourtPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildTestApp(onBookCourt: () => pressed = true));
      await tester.tap(find.text('Đặt sân'));
      expect(pressed, isTrue);
    });

    testWidgets('Mua sắm calls onViewProductsPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildTestApp(onViewProducts: () => pressed = true),
      );
      await tester.tap(find.text('Mua sắm'));
      expect(pressed, isTrue);
    });

    testWidgets('Dịch vụ vợt calls onRacketServicePressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildTestApp(onRacketService: () => pressed = true),
      );
      await tester.tap(find.text('Dịch vụ\nvợt'));
      expect(pressed, isTrue);
    });

    testWidgets('Chi nhánh calls onViewBranchesPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildTestApp(onViewBranches: () => pressed = true),
      );
      await tester.tap(find.text('Chi nhánh'));
      expect(pressed, isTrue);
    });

    testWidgets('no overflow at 320dp width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestApp());

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('no overflow at increased text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: HomeQuickActions(
                onBookCourtPressed: () {},
                onViewProductsPressed: () {},
                onRacketServicePressed: () {},
                onViewBranchesPressed: () {},
              ),
            ),
          ),
        ),
      );
    });
  });
}
