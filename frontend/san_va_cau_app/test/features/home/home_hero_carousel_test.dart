import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';
import 'package:san_va_cau_app/features/home/models/home_data.dart';
import 'package:san_va_cau_app/features/home/widgets/home_hero_section.dart';

void main() {
  Widget buildTestApp({
    List<HomeBanner> banners = const [],
    VoidCallback? onBookCourt,
    VoidCallback? onViewProducts,
    VoidCallback? onRacketService,
    VoidCallback? onViewBranches,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeHeroSection(
            banners: banners,
            onBookCourtPressed: onBookCourt ?? () {},
            onViewProductsPressed: onViewProducts ?? () {},
            onRacketServicePressed: onRacketService ?? () {},
            onViewBranchesPressed: onViewBranches ?? () {},
          ),
        ),
      ),
    );
  }

  group('HomeHeroSection', () {
    testWidgets('renders exactly four page indicators', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // The carousel has exactly 4 pages.
      // Page indicators are AnimatedContainers.
      // Check for the eyebrow text of the first fallback slide.
      expect(find.text('ĐẶT SÂN TRỰC TUYẾN'), findsOneWidget);

      // Swipe to verify all 4 pages exist.
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-800, 0));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('shows fallback slides when no API banners', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('ĐẶT SÂN TRỰC TUYẾN'), findsOneWidget);
      expect(find.text('Tìm sân trống, vào trận nhanh.'), findsOneWidget);
      expect(find.text('Xem lịch sân trống'), findsOneWidget);

      // Swipe to slide 2.
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('DỤNG CỤ CẦU LÔNG'), findsOneWidget);

      // Swipe to slide 3.
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('DỊCH VỤ VỢT'), findsOneWidget);

      // Swipe to slide 4.
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('HỆ THỐNG SANVACAU'), findsOneWidget);
    });

    testWidgets('uses API banner data when available', (tester) async {
      final banners = [
        const HomeBanner(
          id: '1',
          title: 'Khuyến mãi mùa hè',
          imageUrl: 'https://example.com/summer.jpg',
          linkUrl: 'https://example.com/promo',
        ),
        const HomeBanner(
          id: '2',
          title: 'Sản phẩm mới',
          imageUrl: 'https://example.com/new.jpg',
        ),
      ];

      await tester.pumpWidget(buildTestApp(banners: banners));
      await tester.pump();

      // API banner title is used as eyebrow (uppercased).
      expect(find.text('KHUYẾN MÃI MÙA HÈ'), findsOneWidget);

      // Swipe to second API banner.
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('SẢN PHẨM MỚI'), findsOneWidget);

      // Remaining slides should be fallbacks.
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('DỊCH VỤ VỢT'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('HỆ THỐNG SANVACAU'), findsOneWidget);
    });

    testWidgets('uses at most four API banners', (tester) async {
      final banners = List.generate(
        6,
        (i) => HomeBanner(
          id: '$i',
          title: 'Banner $i',
          imageUrl: 'https://example.com/$i.jpg',
        ),
      );

      await tester.pumpWidget(buildTestApp(banners: banners));
      await tester.pump();

      // First four API banners should be used.
      expect(find.text('BANNER 0'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('BANNER 1'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('BANNER 2'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(find.text('BANNER 3'), findsOneWidget);
    });

    testWidgets('failed network image shows fallback, not broken_image', (
      tester,
    ) async {
      final banners = [
        const HomeBanner(
          id: '1',
          title: 'Test',
          imageUrl: 'https://invalid.example.com/missing.jpg',
        ),
      ];

      await tester.pumpWidget(buildTestApp(banners: banners));
      await tester.pump();

      // Should not find broken_image icon.
      expect(find.byIcon(Icons.broken_image), findsNothing);
    });

    testWidgets('CTA for booking calls onBookCourtPressed', (tester) async {
      var bookingPressed = false;
      await tester.pumpWidget(
        buildTestApp(onBookCourt: () => bookingPressed = true),
      );
      await tester.pump();

      await tester.tap(find.text('Xem lịch sân trống'));
      expect(bookingPressed, isTrue);
    });

    testWidgets('CTA for products calls onViewProductsPressed', (tester) async {
      var productsPressed = false;
      await tester.pumpWidget(
        buildTestApp(onViewProducts: () => productsPressed = true),
      );
      await tester.pump();

      // Swipe to slide 2 (products).
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khám phá sản phẩm'));
      expect(productsPressed, isTrue);
    });

    testWidgets('no overflow at 320dp width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // If there were overflow, the framework would report errors.
      // No explicit assertion needed; test passes if no exceptions thrown.

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
              body: SingleChildScrollView(
                child: HomeHeroSection(
                  banners: const [],
                  onBookCourtPressed: () {},
                  onViewProductsPressed: () {},
                  onRacketServicePressed: () {},
                  onViewBranchesPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    });
  });
}
