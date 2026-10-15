import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';

import 'admin_test_accessibility.dart';

import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_booking_list_page.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/booking.dart';

class _FakeBookingApi extends BookingApi {
  _FakeBookingApi(this.fetchBookingsResult, [this.updateResult]);

  final Future<List<Booking>> Function(String? date, String? status)
  fetchBookingsResult;
  final Future<Booking> Function(String id, String status)? updateResult;

  @override
  Future<List<Booking>> getAdminBookings({
    String? branchId,
    String? courtId,
    String? date,
    String? status,
  }) {
    return fetchBookingsResult(date, status);
  }

  @override
  Future<Booking> updateAdminBookingStatus({
    required String id,
    required String status,
  }) async {
    if (updateResult != null) return updateResult!(id, status);
    throw UnimplementedError();
  }
}

Widget _app(BookingApi api) {
  return MaterialApp(home: AdminBookingListPage(bookingApi: api));
}

void main() {
  for (final size in [
    const Size(320, 800),
    const Size(375, 800),
    const Size(800, 375),
  ]) {
    testWidgets(
      'booking list and detail remain usable at $size with large text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final booking = Booking(
          id: '99',
          status: 'BOOKED',
          totalAmount: '200000',
          branch: const BookingBranch(
            id: '2',
            name: 'Chi nhánh có tên dài để kiểm tra hiển thị',
          ),
          court: const BookingCourt(id: '3', name: 'Sân số 1'),
          customer: const BookingCustomer(
            id: '1',
            fullName: 'Khách hàng có tên dài',
            phone: '0987654321',
          ),
          bookingDate: DateTime(2026, 10, 12),
          slots: const [
            BookingTimeSlot(
              id: '1',
              timeSlotId: '1',
              startTime: '10:00',
              endTime: '11:00',
              priceAtBooking: '200000',
            ),
          ],
        );
        final api = _FakeBookingApi((date, status) async => [booking]);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: AdminBookingListPage(bookingApi: api),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectAdminAccessibility(tester);
        await tester.tap(find.text('Lịch #99'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectAdminAccessibility(tester);
        await tester.drag(find.byType(ListView).last, const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectAdminAccessibility(tester);
        expect(find.widgetWithText(ElevatedButton, 'Hủy lịch'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'cancellation requires confirmation and disables actions during submission',
    (tester) async {
      final result = Completer<Booking>();
      var calls = 0;
      final booking = Booking(
        id: '99',
        status: 'BOOKED',
        totalAmount: '200000',
        bookingDate: DateTime(2026, 10, 12),
        branch: const BookingBranch(id: '2', name: 'Chi nhánh'),
        court: const BookingCourt(id: '3', name: 'Sân'),
        slots: [],
      );
      final api = _FakeBookingApi((date, status) async => [booking], (
        id,
        status,
      ) {
        calls++;
        expect(status, 'CANCELLED');
        return result.future;
      });
      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch #99'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hủy lịch'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hủy lịch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Hủy lịch'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Nhận sân'),
            )
            .onPressed,
        isNull,
      );
      result.completeError(
        const ApiException(statusCode: 400, message: 'Không thể hủy'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không thể hủy'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Hủy lịch'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('renders loading state initially', (tester) async {
    final api = _FakeBookingApi((date, status) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return [];
    });

    await tester.pumpWidget(_app(api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders error and retry state', (tester) async {
    var fail = true;
    final api = _FakeBookingApi((date, status) async {
      if (fail) {
        throw const ApiException(statusCode: 500, message: 'Lỗi server');
      }
      return [];
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải danh sách lịch đặt sân'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không có lịch đặt sân nào'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    final api = _FakeBookingApi((date, status) async => []);

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Không có lịch đặt sân nào'), findsOneWidget);
  });

  testWidgets('status filter sends the correct backend status', (tester) async {
    String? requestedStatus;
    final api = _FakeBookingApi((date, status) async {
      requestedStatus = status;
      return [];
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(requestedStatus, null);

    await tester.tap(find.text('Đã nhận sân'));
    await tester.pumpAndSettle();

    expect(requestedStatus, 'CHECKED_IN');
  });

  testWidgets('date filter sends YYYY-MM-DD and clear removes it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? requestedDate;
    final api = _FakeBookingApi((date, status) async {
      requestedDate = date;
      return [];
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(requestedDate, null);

    // Open Date Picker
    await tester.tap(find.text('Chọn ngày...'));
    await tester.pumpAndSettle();

    // Select OK on current date
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(requestedDate, isNotNull);
    expect(requestedDate!.length, 10); // YYYY-MM-DD

    // Clear Date
    await tester.tap(find.byTooltip('Xóa ngày'));
    await tester.pumpAndSettle();

    expect(requestedDate, null);
  });

  testWidgets(
    'tapping a booking opens detail and renders correctly without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(
        360,
        800,
      ); // realistic narrow viewport
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final booking = Booking(
        id: '99',
        status: 'BOOKED',
        totalAmount: '200000',
        bookingDate: DateTime.tryParse('2026-10-06T00:00:00Z'),
        createdAt: DateTime.tryParse('2026-10-01T10:00:00Z'),
        customer: const BookingCustomer(
          id: '1',
          fullName: 'John Wick',
          phone: '0987654321',
        ),
        branch: const BookingBranch(id: '2', name: 'Chi nhánh VIP'),
        court: const BookingCourt(id: '3', name: 'Sân số 1'),
        paymentMethod: 'CASH',
        paymentStatus: 'UNPAID',
        slots: [
          const BookingTimeSlot(
            id: '1',
            timeSlotId: '1',
            startTime: '10:00:00',
            endTime: '11:00:00',
            priceAtBooking: '200000',
          ),
        ],
      );

      final api = _FakeBookingApi((date, status) async => [booking]);

      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      expect(find.text('Lịch #99'), findsOneWidget);

      // Tap booking card
      await tester.tap(find.text('Lịch #99'));
      await tester.pumpAndSettle();

      // Verify detail page
      expect(find.text('Chi tiết lịch đặt'), findsOneWidget);
      expect(find.text('John Wick'), findsOneWidget);
      expect(find.text('0987654321'), findsOneWidget);
      expect(find.text('Chi nhánh VIP'), findsOneWidget);
      expect(find.text('Sân số 1'), findsOneWidget);
      expect(find.text('Chưa thanh toán · Cần thu 200.000 đ'), findsOneWidget);
      expect(find.text('Thu tiền mặt'), findsOneWidget);
      await tester.tap(find.text('Thu tiền mặt'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận thu tiền mặt'), findsOneWidget);
      expect(find.text('Đã nhận đủ tiền'), findsOneWidget);
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('10:00 - 11:00'), 150, scrollable: find.byType(Scrollable).first);
      expect(find.text('10:00 - 11:00'), findsOneWidget);

      // Actions should be present for BOOKED
      expect(find.widgetWithText(ElevatedButton, 'Nhận sân'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Hủy lịch'), findsOneWidget);
    },
  );

  testWidgets('BOOKED actions and CHECKED_IN actions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Booking booking = Booking(
      id: '99',
      status: 'BOOKED',
      paymentStatus: 'PAID',
      totalAmount: '200000',
      branch: const BookingBranch(id: '2', name: 'Chi nhánh VIP'),
      court: const BookingCourt(id: '3', name: 'Sân số 1'),
      bookingDate: DateTime.now(),
      slots: [],
    );

    final api = _FakeBookingApi((date, status) async => [booking], (
      id,
      status,
    ) async {
      booking = Booking(
        id: '99',
        status: status,
        paymentStatus: 'PAID',
        totalAmount: '200000',
        branch: const BookingBranch(id: '2', name: 'Chi nhánh VIP'),
        court: const BookingCourt(id: '3', name: 'Sân số 1'),
        bookingDate: DateTime.now(),
        slots: [],
      );
      return booking;
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch #99'));
    await tester.pumpAndSettle();

    // BOOKED -> CHECKED_IN
    await tester.tap(find.widgetWithText(ElevatedButton, 'Nhận sân'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận nhận sân'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    // Verify snackbar
    expect(find.text('Cập nhật trạng thái thành công'), findsOneWidget);

    // List page reloaded -> Open detail again
    await tester.tap(find.text('Lịch #99'));
    await tester.pumpAndSettle();

    // CHECKED_IN -> COMPLETED
    expect(
      find.widgetWithText(ElevatedButton, 'Hoàn tất'),
      findsOneWidget,
    ); // Action button
    expect(
      find.widgetWithText(ElevatedButton, 'Nhận sân'),
      findsNothing,
    ); // Should not be there

    await tester.tap(find.widgetWithText(ElevatedButton, 'Hoàn tất'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận hoàn tất'), findsOneWidget);
    await tester.tap(find.text('Bỏ qua')); // Test cancel dialog
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Hoàn tất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    // List page reloaded -> Open detail again
    await tester.tap(find.text('Lịch #99'));
    await tester.pumpAndSettle();

    // Final statuses hide actions
    expect(find.widgetWithText(ElevatedButton, 'Nhận sân'), findsNothing);
    expect(
      find.widgetWithText(ElevatedButton, 'Hoàn tất'),
      findsNothing,
    ); // Button should be gone.
    // Ensure no ElevatedButton is present in the bottom bar
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets(
    'failed update keeps the detail page and displays the backend error',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final booking = Booking(
        id: '99',
        status: 'BOOKED',
        totalAmount: '200000',
        branch: const BookingBranch(id: '2', name: 'Chi nhánh VIP'),
        court: const BookingCourt(id: '3', name: 'Sân số 1'),
        bookingDate: DateTime.now(),
        slots: [],
      );

      final api = _FakeBookingApi((date, status) async => [booking], (
        id,
        status,
      ) async {
        throw const ApiException(
          statusCode: 400,
          message: 'Invalid state transition',
        );
      });

      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch #99'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nhận sân'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Should still be on detail page
      expect(find.text('Chi tiết lịch đặt'), findsOneWidget);
      expect(
        find.text('Invalid state transition'),
        findsOneWidget,
      ); // SnackBar message
    },
  );
}
