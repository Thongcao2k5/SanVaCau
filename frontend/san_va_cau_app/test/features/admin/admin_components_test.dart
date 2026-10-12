import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/admin/theme/admin_theme.dart';
import 'package:san_va_cau_app/features/admin/widgets/admin_ui.dart';

void main() {
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
}
