import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/widgets/auth_primary_button.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/booking.dart';
import 'package:san_va_cau_app/features/payments/data/payment_api.dart';
import 'package:san_va_cau_app/features/payments/models/payment.dart';
import 'package:san_va_cau_app/features/booking/models/court.dart';
import 'package:san_va_cau_app/features/booking/pages/booking_page.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';

const branch = Branch(
  id: '1',
  name: 'SanVaCau Bình Thạnh',
  address: '123 Bình Thạnh, TP.HCM',
  openingTime: '06:00:00',
  closingTime: '22:00:00',
  status: 'ACTIVE',
);

class FakeBranches extends BranchApi {
  @override
  Future<List<Branch>> getBranches() async => [branch];
}

class FakeBooking extends BookingApi {
  final calls = <String>[];
  Map<String, List<String>>? bookedCourts;
  String? method;

  bool fail = false;
  @override
  Future<List<Court>> getCourts({String? branchId}) async => [
    const Court(id: '1', branchId: '1', name: 'Sân 1', status: 'ACTIVE'),
    const Court(id: '2', branchId: '1', name: 'Sân 2', status: 'ACTIVE'),
  ];
  @override
  Future<List<BookingSlot>> getAvailability({
    required String courtId,
    required String date,
  }) async {
    calls.add('$courtId/$date');
    if (fail) throw Exception('offline');
    return [
      const BookingSlot(
        timeSlotId: '1',
        startTime: '06:00:00',
        endTime: '06:30:00',
        price: 40000,
        isBooked: false,
      ),
      const BookingSlot(
        timeSlotId: '2',
        startTime: '06:30:00',
        endTime: '07:00:00',
        price: 40000,
        isBooked: true,
      ),
      const BookingSlot(
        timeSlotId: '3',
        startTime: '07:00:00',
        endTime: '07:30:00',
        price: 40000,
        isBooked: false,
      ),
    ];
  }

  @override
  Future<List<Booking>> createBookings({
    required String bookingDate,
    required Map<String, List<String>> courtSlots,
    String paymentMethod = 'CASH',
  }) async {
    bookedCourts = courtSlots;
    method = paymentMethod;
    return [
      for (final id in courtSlots.keys)
        Booking.fromJson({
          'id': id,
          'court': {'id': id, 'name': 'Sân $id'},
          'status': 'BOOKED',
          'paymentStatus': 'UNPAID',
          'totalAmount': '40000',
        }),
    ];
  }
}

class FakePayments extends PaymentApi {
  @override
  Future<void> ensureVnpayConfigured() async {}
  @override
  Future<void> ensureMomoConfigured() async {}
  @override
  Future<Payment> createPayment({
    required String targetType,
    required String targetId,
    required String provider,
  }) async {
    throw const ApiException(
      statusCode: 503,
      message: 'Cổng thanh toán tạm gián đoạn',
    );
  }
}

class FakeLogin extends AuthApi {
  @override
  Future<AuthUser> getProfile() async =>
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
  @override
  Future<void> logout() async => TokenStorage().clearToken();
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await TokenStorage().saveToken('logged-in');
    return const AuthSession(
      token: 'logged-in',
      user: AuthUser(
        id: '1',
        email: 'customer@example.com',
        fullName: 'Khách hàng',
        role: 'CUSTOMER',
        status: 'ACTIVE',
      ),
    );
  }
}

Future<void> pumpPage(
  WidgetTester tester,
  FakeBooking api, {
  bool loggedIn = true,
}) async {
  SharedPreferences.setMockInitialValues(
    loggedIn ? {'auth_token': 'test-token'} : {},
  );
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: BookingPage(
        branchApi: FakeBranches(),
        bookingApi: api,
        authApi: FakeLogin(),
        paymentApi: FakePayments(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('branch-1')));
  await tester.pumpAndSettle();
  // Select tomorrow so all test slots are in the future regardless of test time.
  await tester.tap(find.byIcon(Icons.calendar_month_outlined));
  await tester.pumpAndSettle();
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  if (tomorrow.month != DateTime.now().month) {
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('${tomorrow.day}').last);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Guest logs in and returns with all selections without submitting',
    (tester) async {
      final api = FakeBooking();
      await pumpPage(tester, api, loggedIn: false);
      await tester.tap(find.byKey(const ValueKey('slot-1-1')));
      await tester.tap(find.byKey(const ValueKey('slot-2-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TIẾP THEO'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập để đặt sân'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'customer@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'Customer123',
      );
      await tester.ensureVisible(find.byType(AuthPrimaryButton));
      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập để đặt sân'), findsNothing);
      expect(find.text('2 sân • 2 khung giờ'), findsOneWidget);
      expect(api.bookedCourts, isNull);
      await tester.tap(find.text('TIẾP THEO'));
      await tester.pumpAndSettle();
      expect(find.text('Sân 1: 06:00 – 06:30'), findsOneWidget);
      expect(find.text('Sân 2: 06:00 – 06:30'), findsOneWidget);
      expect(api.bookedCourts, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Canceling login keeps booking selection', (tester) async {
    final api = FakeBooking();
    await pumpPage(tester, api, loggedIn: false);
    await tester.tap(find.byKey(const ValueKey('slot-1-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TIẾP THEO'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('1 sân • 1 khung giờ'), findsOneWidget);
    expect(api.bookedCourts, isNull);
  });
  testWidgets('Branch opens all court rows; booked cells cannot be selected', (
    tester,
  ) async {
    final api = FakeBooking();
    await pumpPage(tester, api);
    expect(find.text('Sân 1'), findsOneWidget);
    expect(find.text('Sân 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slot-1-2')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'TIẾP THEO'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('slot-1-1')));
    await tester.pumpAndSettle();
    expect(find.text('40.000 đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Multiple courts retain their selections and submit together', (
    tester,
  ) async {
    final api = FakeBooking();
    await pumpPage(tester, api);
    await tester.tap(find.byKey(const ValueKey('slot-1-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-1-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-2-1')));
    await tester.pumpAndSettle();
    expect(find.text('2 sân • 3 khung giờ'), findsOneWidget);
    expect(find.text('120.000 đ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slot-2-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 sân • 2 khung giờ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slot-2-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TIẾP THEO'));
    await tester.pumpAndSettle();
    expect(find.text('Sân 1: 06:00 – 06:30'), findsOneWidget);
    expect(find.text('Sân 2: 06:00 – 06:30'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận đặt sân'));
    await tester.pumpAndSettle();
    expect(api.bookedCourts, {
      '1': ['1', '3'],
      '2': ['1'],
    });

    expect(api.method, 'CASH');
    expect(
      find.text('Đặt sân thành công. Vui lòng thanh toán tiền mặt tại sân.'),
      findsOneWidget,
    );
    expect(find.text('VNPAY'), findsNothing);
    expect(find.text('Đã thanh toán'), findsNothing);
    expect(find.text('Thanh toán'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'TIẾP THEO'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Date changes reset selection and reload every court', (
    tester,
  ) async {
    final api = FakeBooking();
    await pumpPage(tester, api);
    await tester.tap(find.byKey(const ValueKey('slot-1-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'TIẾP THEO'))
          .onPressed,
      isNull,
    );
    expect(api.calls.length, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed availability can be retried', (tester) async {
    final api = FakeBooking()..fail = true;
    await pumpPage(tester, api);
    expect(find.text('Không thể tải khung giờ.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slot-1-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
