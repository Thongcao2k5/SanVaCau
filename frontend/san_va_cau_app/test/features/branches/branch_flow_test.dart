import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/court.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';
import 'package:san_va_cau_app/features/branches/pages/branch_detail_page.dart';
import 'package:san_va_cau_app/features/branches/pages/branch_list_page.dart';

const _testBranch1 = Branch(
  id: 'branch-101',
  name: 'Chi nhánh Quận 7',
  address: '456 Nguyễn Thị Thập, Q7',
  openingTime: '06:00',
  closingTime: '22:00',
  phone: '0901234567',
  status: 'ACTIVE',
  description: 'Sân cầu lông tiêu chuẩn quốc tế',
);

const _testBranch2 = Branch(
  id: 'branch-102',
  name: 'Chi nhánh Bình Thạnh',
  address: '123 Điện Biên Phủ, Bình Thạnh',
  openingTime: '05:30',
  closingTime: '23:00',
  phone: '0909876543',
  status: 'ACTIVE',
);

class _TestBranchApi extends BranchApi {
  @override
  Future<List<Branch>> getBranches() async => const [
    _testBranch1,
    _testBranch2,
  ];
}

class _TestBookingApi extends BookingApi {
  @override
  Future<List<Court>> getCourts({String? branchId}) async => const [
    Court(
      id: 'court-101',
      branchId: 'branch-101',
      name: 'Sân VIP 1',
      description: 'Sân thảm tiêu chuẩn BWF',
      status: 'ACTIVE',
    ),
  ];
}

void main() {
  group('BranchListPage & BranchDetailPage redesign flows', () {
    testWidgets(
      'cards render branch details, tapping opens BranchDetailPage, and Đặt sân ngay returns branch',
      (tester) async {
        Branch? returnedBranch;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedBranch = await Navigator.of(context).push<Branch>(
                      MaterialPageRoute<Branch>(
                        builder: (_) => BranchListPage(
                          branchApi: _TestBranchApi(),
                          bookingApi: _TestBookingApi(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Branches'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open branch list
        await tester.tap(find.text('Open Branches'));
        await tester.pumpAndSettle();

        // Card displays name, address, schedule, and view affordance
        expect(find.text('Chi nhánh Quận 7'), findsOneWidget);
        expect(find.text('456 Nguyễn Thị Thập, Q7'), findsOneWidget);
        expect(find.text('06:00 - 22:00'), findsOneWidget);
        expect(find.text('Xem thông tin chi nhánh'), findsWidgets);
        expect(find.text('Đang hoạt động'), findsWidgets);

        // Tap on card opens BranchDetailPage
        await tester.tap(find.text('Chi nhánh Quận 7'));
        await tester.pumpAndSettle();

        // BranchDetailPage content verification
        expect(find.byType(BranchDetailPage), findsOneWidget);
        expect(find.text('Chi tiết chi nhánh'), findsOneWidget);
        expect(find.text('Sân cầu lông tiêu chuẩn quốc tế'), findsOneWidget);
        expect(find.text('Địa chỉ'), findsOneWidget);
        expect(find.text('456 Nguyễn Thị Thập, Q7'), findsOneWidget);
        expect(find.text('Giờ hoạt động'), findsOneWidget);
        expect(find.text('06:00 - 22:00'), findsOneWidget);
        expect(find.text('Điện thoại'), findsOneWidget);
        expect(find.text('0901234567'), findsOneWidget);
        expect(find.text('Sân tại chi nhánh'), findsOneWidget);
        expect(find.text('Sân VIP 1'), findsOneWidget);
        expect(find.text('Sân thảm tiêu chuẩn BWF'), findsOneWidget);

        // CTA Đặt sân ngay
        final cta = find.widgetWithText(FilledButton, 'Đặt sân ngay');
        expect(cta, findsOneWidget);

        await tester.tap(cta);
        await tester.pumpAndSettle();

        // Stack popped and returned branch
        expect(find.byType(BranchDetailPage), findsNothing);
        expect(find.byType(BranchListPage), findsNothing);
        expect(returnedBranch?.id, 'branch-101');
      },
    );

    testWidgets('client-side search filters by name and address', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BranchListPage(
            branchApi: _TestBranchApi(),
            bookingApi: _TestBookingApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chi nhánh Quận 7'), findsOneWidget);
      expect(find.text('Chi nhánh Bình Thạnh'), findsOneWidget);

      // Search by name
      await tester.enterText(find.byType(TextField), 'quận 7');
      await tester.pumpAndSettle();

      expect(find.text('Chi nhánh Quận 7'), findsOneWidget);
      expect(find.text('Chi nhánh Bình Thạnh'), findsNothing);

      // Search by address
      await tester.enterText(find.byType(TextField), 'điện biên phủ');
      await tester.pumpAndSettle();

      expect(find.text('Chi nhánh Quận 7'), findsNothing);
      expect(find.text('Chi nhánh Bình Thạnh'), findsOneWidget);

      // Search with no matching result shows empty state
      await tester.enterText(find.byType(TextField), 'hà nội');
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy chi nhánh phù hợp'), findsOneWidget);
      expect(find.text('Thử tìm với tên hoặc địa chỉ khác.'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Xóa tìm kiếm'),
        findsOneWidget,
      );

      // Tap clear search action
      await tester.tap(find.widgetWithText(OutlinedButton, 'Xóa tìm kiếm'));
      await tester.pumpAndSettle();

      // List is restored
      expect(find.text('Chi nhánh Quận 7'), findsOneWidget);
      expect(find.text('Chi nhánh Bình Thạnh'), findsOneWidget);
      expect(find.text('Không tìm thấy chi nhánh phù hợp'), findsNothing);
    });

    testWidgets('clear search via suffix icon restores full list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BranchListPage(
            branchApi: _TestBranchApi(),
            bookingApi: _TestBookingApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'quận 7');
      await tester.pumpAndSettle();
      expect(find.text('Chi nhánh Bình Thạnh'), findsNothing);

      // Tap suffix clear icon
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();

      expect(find.text('Chi nhánh Quận 7'), findsOneWidget);
      expect(find.text('Chi nhánh Bình Thạnh'), findsOneWidget);
    });

    testWidgets('no layout overflow at 320dp width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Branch list page at 320dp
      await tester.pumpWidget(
        MaterialApp(
          home: BranchListPage(
            branchApi: _TestBranchApi(),
            bookingApi: _TestBookingApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Branch detail page at 320dp
      await tester.pumpWidget(
        MaterialApp(
          home: BranchDetailPage(
            branch: _testBranch1,
            bookingApi: _TestBookingApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no layout overflow with text scale 1.5', (tester) async {
      // Branch list page with text scale 1.5
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            home: BranchListPage(
              branchApi: _TestBranchApi(),
              bookingApi: _TestBookingApi(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Branch detail page with text scale 1.5
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            home: BranchDetailPage(
              branch: _testBranch1,
              bookingApi: _TestBookingApi(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
