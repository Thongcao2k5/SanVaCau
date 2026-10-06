import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/account_page.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';
import 'package:san_va_cau_app/features/reviews/data/review_api.dart';
import 'package:san_va_cau_app/features/reviews/models/review.dart';
import 'package:san_va_cau_app/features/reviews/pages/my_reviews_page.dart';

class _FakeReviewApi extends ReviewApi {
  _FakeReviewApi(this.loader);

  final Future<ReviewPage> Function() loader;

  @override
  Future<ReviewPage> getMyReviews({
    int page = 1,
    int limit = 20,
    String? targetType,
    String? status,
  }) {
    return loader();
  }
}

class _FakeAuthApi extends AuthApi {
  @override
  Future<AuthUser> getProfile() async {
    return const AuthUser(
      id: '1',
      email: 'customer@example.com',
      fullName: 'Khach hang',
      role: 'CUSTOMER',
      status: 'ACTIVE',
    );
  }
}

class _FakeNotificationApi extends NotificationApi {
  @override
  Future<int> getUnreadCount() async => 0;
}

ReviewPage _page([List<Review> items = const []]) {
  return ReviewPage(
    items: items,
    page: 1,
    limit: 20,
    total: items.length,
    totalPages: items.isEmpty ? 0 : 1,
  );
}

Review _review() {
  return Review(
    id: '9',
    userId: '1',
    targetType: 'PRODUCT',
    targetId: '7',
    target: const ReviewTarget(
      type: 'PRODUCT',
      id: '7',
      name: 'Yonex Astrox 100 ZZ',
    ),
    rating: 4,
    comment: 'Vot can bang, de danh.',
    status: 'PUBLISHED',
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 2),
  );
}

Widget _app(ReviewApi api) {
  return MaterialApp(home: MyReviewsPage(reviewApi: api));
}

void main() {
  testWidgets('shows loading while personal reviews are requested', (
    tester,
  ) async {
    final completer = Completer<ReviewPage>();

    await tester.pumpWidget(_app(_FakeReviewApi(() => completer.future)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows review target, rating, comment, status, and date', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_FakeReviewApi(() async => _page([_review()]))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yonex Astrox 100 ZZ'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Đã hiển thị'), findsOneWidget);
    expect(find.text('Vot can bang, de danh.'), findsOneWidget);
    expect(find.text('02/10/2026'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await tester.pumpWidget(_app(_FakeReviewApi(() async => _page())));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có đánh giá nào'), findsOneWidget);
  });

  testWidgets('shows an error and retries the request', (tester) async {
    var calls = 0;
    final api = _FakeReviewApi(() async {
      calls += 1;
      if (calls == 1) throw Exception('network');
      return _page();
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải đánh giá'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Bạn chưa có đánh giá nào'), findsOneWidget);
  });

  testWidgets('opens My Reviews from the account menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          authApi: _FakeAuthApi(),
          notificationApi: _FakeNotificationApi(),
          myReviewsPage: const Scaffold(body: Text('Trang đánh giá')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Đánh giá của tôi'), findsOneWidget);
    await tester.tap(find.text('Đánh giá của tôi'));
    await tester.pumpAndSettle();

    expect(find.text('Trang đánh giá'), findsOneWidget);
  });
}
