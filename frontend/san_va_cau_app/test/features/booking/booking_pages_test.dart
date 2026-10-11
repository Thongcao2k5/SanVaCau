import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/booking.dart';
import 'package:san_va_cau_app/features/booking/pages/booking_detail_page.dart';
import 'package:san_va_cau_app/features/booking/pages/booking_history_page.dart';

class _FakeBookingApi extends BookingApi {
  _FakeBookingApi({this.bookings = const [], this.listError});

  final List<Booking> bookings;
  final Object? listError;
  int cancelCallCount = 0;

  @override
  Future<List<Booking>> getMyBookings() async {
    if (listError case final error?) throw error;
    return bookings;
  }

  @override
  Future<void> cancelBooking(String id) async {
    cancelCallCount += 1;
  }
}

final _booking = Booking(
  id: 'booking-1',
  court: const BookingCourt(id: 'court-1', name: 'Sân 1'),
  branch: const BookingBranch(id: 'branch-1', name: 'Cơ sở Quận 1'),
  bookingDate: DateTime(2026, 10, 12),
  status: 'BOOKED',
  totalAmount: '100000',
  paymentMethod: 'CASH',
  paymentStatus: 'UNPAID',
  slots: const [
    BookingTimeSlot(
      id: 'booking-slot-1',
      timeSlotId: 'slot-1',
      startTime: '08:00',
      endTime: '09:00',
      priceAtBooking: '100000',
    ),
  ],
);

void main() {
  testWidgets('booking history exposes API errors and retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookingHistoryPage(
          bookingApi: _FakeBookingApi(
            listError: const ApiException(
              statusCode: 503,
              message: 'Không thể tải lịch đặt lúc này',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải lịch đặt lúc này'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('booking history renders court, branch and booked status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookingHistoryPage(
          bookingApi: _FakeBookingApi(bookings: [_booking]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhịp sân của bạn'), findsNothing);
    expect(find.text('Sân 1'), findsOneWidget);
    expect(find.text('Cơ sở Quận 1'), findsOneWidget);
    expect(find.text('Đã đặt'), findsOneWidget);
  });

  testWidgets('booked booking can be cancelled after confirmation', (
    tester,
  ) async {
    final bookingApi = _FakeBookingApi();
    await tester.pumpWidget(
      MaterialApp(
        home: BookingDetailPage(booking: _booking, bookingApi: bookingApi),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Hủy lịch đặt sân'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hủy lịch đặt sân'));
    await tester.pumpAndSettle();
    expect(find.text('Hủy lịch đặt sân?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Hủy lịch'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(bookingApi.cancelCallCount, 1);
  });
}
