import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';

import 'admin_test_accessibility.dart';

import 'package:san_va_cau_app/features/admin/theme/admin_theme.dart';
import 'package:san_va_cau_app/features/admin/widgets/admin_ui.dart';

void main() {
  test('light admin palette uses the approved wine design tokens', () {
    expect(AdminTheme.canvas, const Color(0xFFF7F5F3));
    expect(AdminTheme.surface, const Color(0xFFFFFFFF));
    expect(AdminTheme.primary, const Color(0xFFB4232F));
    expect(AdminTheme.softWine, const Color(0xFFF8E7EA));
    expect(AdminTheme.textPrimary, const Color(0xFF22242A));
    expect(AdminTheme.textSecondary, const Color(0xFF6E737C));
    expect(AdminTheme.border, const Color(0xFFE7E1E2));
  });

  testWidgets(
    'status badges have readable contrast and complete semantic labels',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AdminTheme.data(AppTheme.light()),
          home: Scaffold(
            body: Wrap(
              children: [
                for (final tone in AdminStatusTone.values)
                  AdminStatusBadge(label: 'Trạng thái $tone', tone: tone),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectAdminAccessibility(tester);
      final semantics = tester.ensureSemantics();
      try {
        for (final tone in AdminStatusTone.values) {
          expect(
            find.bySemanticsLabel('Trạng thái: Trạng thái $tone'),
            findsOneWidget,
          );
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'shared loading, error and empty states remain readable in landscape',
    (tester) async {
      tester.view.physicalSize = const Size(800, 375);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      for (final loading in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AdminTheme.data(AppTheme.light()),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: AdminStateView(
                  icon: Icons.cloud_off_rounded,
                  title: loading
                      ? 'Đang tải nội dung'
                      : 'Không thể tải nội dung',
                  message: 'Thông tin trạng thái rõ ràng, có thể đọc ở màn hình ngang.',
                  isLoading: loading,
                  actionLabel: loading ? null : 'Thử tải lại nội dung',
                  onAction: () => retries++,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        if (!loading) {
          await tester.pumpAndSettle();
          await tester.tap(find.text('Thử tải lại nội dung'));
          expect(retries, 1);
          await expectAdminAccessibility(tester);
        } else {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
      }
    },
  );
  testWidgets('shared admin components support large text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            backgroundColor: AdminTheme.canvas,
            body: Column(
              children: [
                AdminPageHeader(
                  title: 'Vận hành',
                  subtitle: 'Theo dõi và xử lý hoạt động hằng ngày',
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: AdminSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AdminIconBox(
                              icon: Icons.calendar_month_rounded,
                              color: AdminTheme.info,
                            ),
                            SizedBox(width: 12),
                            Expanded(child: Text('Lịch đặt sân trong ngày')),
                          ],
                        ),
                        SizedBox(height: 12),
                        AdminStatusBadge(
                          label: 'Đang xử lý',
                          tone: AdminStatusTone.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vận hành'), findsOneWidget);
    expect(find.text('Đang xử lý'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page header defaults to the light admin surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AdminTheme.data(AppTheme.light()),
        home: const Scaffold(
          body: AdminPageHeader(
            title: 'Vận hành',
            subtitle: 'Theo dõi hoạt động hằng ngày',
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Vận hành'));
    expect(title.style?.color, AdminTheme.textPrimary);
    expect(find.text('Theo dõi hoạt động hằng ngày'), findsOneWidget);
  });
}
