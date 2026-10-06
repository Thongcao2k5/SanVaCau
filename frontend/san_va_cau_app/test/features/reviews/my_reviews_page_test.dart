import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/account_page.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';
import 'package:san_va_cau_app/features/reviews/data/review_api.dart';
import 'package:san_va_cau_app/features/reviews/models/review.dart';
import 'package:san_va_cau_app/features/reviews/pages/my_reviews_page.dart';

class _FakeReviewApi extends ReviewApi {
  _FakeReviewApi(this.loader, {this.updater});

  final Future<ReviewPage> Function() loader;
  final Future<Review> Function(String reviewId, int rating, String? comment)?
  updater;

  @override
  Future<ReviewPage> getMyReviews({
    int page = 1,
    int limit = 20,
    String? targetType,
    String? status,
  }) {
    return loader();
  }

  @override
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) {
    return updater!(reviewId, rating, comment);
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

  testWidgets('edits a review and reloads data from the API', (tester) async {
    var loadCalls = 0;
    String? submittedComment;
    int? submittedRating;
    final updatedReview = Review(
      id: '9',
      userId: '1',
      targetType: 'PRODUCT',
      targetId: '7',
      target: _review().target,
      rating: 2,
      comment: 'Noi dung moi',
      status: 'PUBLISHED',
      createdAt: _review().createdAt,
      updatedAt: DateTime.utc(2026, 10, 3),
    );
    final api = _FakeReviewApi(
      () async {
        loadCalls += 1;
        return _page([loadCalls == 1 ? _review() : updatedReview]);
      },
      updater: (reviewId, rating, comment) async {
        expect(reviewId, '9');
        submittedRating = rating;
        submittedComment = comment;
        return updatedReview;
      },
    );

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sửa đánh giá'));
    await tester.pumpAndSettle();

    expect(find.text('Vot can bang, de danh.'), findsOneWidget);
    await tester.tap(find.byTooltip('Chọn 2 sao'));
    await tester.enterText(find.byType(TextFormField), 'Noi dung moi');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(submittedRating, 2);
    expect(submittedComment, 'Noi dung moi');
    expect(loadCalls, 2);
    expect(find.text('Noi dung moi'), findsOneWidget);
  });

  testWidgets('validates the comment before updating', (tester) async {
    var updateCalls = 0;
    final api = _FakeReviewApi(
      () async => _page([_review()]),
      updater: (_, _, _) async {
        updateCalls += 1;
        return _review();
      },
    );

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sửa đánh giá'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'x' * 1001);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();

    expect(find.text('Nhận xét tối đa 1000 ký tự'), findsOneWidget);
    expect(updateCalls, 0);
  });

  testWidgets('keeps the edit form data when the API fails', (tester) async {
    final api = _FakeReviewApi(
      () async => _page([_review()]),
      updater: (_, _, _) async => throw const ApiException(
        statusCode: 500,
        message: 'Không thể cập nhật đánh giá',
      ),
    );

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sửa đánh giá'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Noi dung dang soan');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Sửa đánh giá'), findsOneWidget);
    expect(find.text('Noi dung dang soan'), findsOneWidget);
    expect(find.text('Không thể cập nhật đánh giá'), findsOneWidget);
  });
}
