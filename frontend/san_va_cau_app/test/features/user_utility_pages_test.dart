import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/favorites/data/favorite_api.dart';
import 'package:san_va_cau_app/features/favorites/models/favorite_item.dart';
import 'package:san_va_cau_app/features/favorites/pages/favorites_page.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';
import 'package:san_va_cau_app/features/notifications/models/notification_item.dart';
import 'package:san_va_cau_app/features/notifications/pages/notifications_page.dart';
import 'package:san_va_cau_app/features/search/data/search_api.dart';
import 'package:san_va_cau_app/features/search/models/search_result.dart';
import 'package:san_va_cau_app/features/search/pages/search_page.dart';

class _FakeNotificationApi extends NotificationApi {
  int markAllCount = 0;

  @override
  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async => [
    NotificationItem(
      id: 'notification-1',
      type: 'SYSTEM',
      title: 'Đơn hàng đã được xác nhận',
      message: 'Đơn hàng của bạn đang được chuẩn bị.',
      isRead: false,
      createdAt: DateTime(2026),
    ),
  ];

  @override
  Future<void> markAllAsRead() async {
    markAllCount += 1;
  }
}

class _FakeFavoriteApi extends FavoriteApi {
  @override
  Future<List<FavoriteItem>> getFavorites({
    String targetType = 'PRODUCT',
  }) async => const [
    FavoriteItem(
      id: 'favorite-1',
      targetType: 'PRODUCT',
      targetId: 'product-1',
      targetName: 'Vợt cầu lông',
      targetImageUrl: 'assets/demo/product-shoes.jpg',
      isActive: true,
    ),
  ];
}

class _EmptyNotificationApi extends NotificationApi {
  @override
  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async => const [];
}

class _FakeSearchApi extends SearchApi {
  int callCount = 0;
  String? lastQuery;

  @override
  Future<SearchData> getSearchResults({
    required String query,
    String type = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    callCount += 1;
    lastQuery = query;
    return const SearchData(
      query: 'vợt',
      type: 'ALL',
      items: [
        SearchResultItem(
          type: 'PRODUCT',
          id: 'product-1',
          title: 'Vợt cầu lông',
          subtitle: 'Vợt dành cho người mới',
          imageUrl: null,
          metadata: {},
        ),
      ],
      counts: {'PRODUCT': 1},
    );
  }
}

void main() {
  testWidgets('notifications can be marked all as read', (tester) async {
    final api = _FakeNotificationApi();
    await tester.pumpWidget(
      MaterialApp(home: NotificationsPage(notificationApi: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đơn hàng đã được xác nhận'), findsOneWidget);
    await tester.tap(find.byTooltip('Đánh dấu tất cả đã đọc'));
    await tester.pumpAndSettle();

    expect(api.markAllCount, 1);
    expect(find.text('Đã đánh dấu tất cả là đã đọc'), findsOneWidget);
  });

  testWidgets('notifications use the shared empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(notificationApi: _EmptyNotificationApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có thông báo'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tải lại'), findsOneWidget);
  });

  testWidgets('favorites page renders saved products', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FavoritesPage(favoriteApi: _FakeFavoriteApi())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bộ sưu tập của bạn'), findsOneWidget);
    expect(find.text('Vợt cầu lông'), findsOneWidget);
    expect(find.text('Đang kinh doanh'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
  });

  testWidgets('search waits for debounce and renders API results', (
    tester,
  ) async {
    final api = _FakeSearchApi();
    await tester.pumpWidget(MaterialApp(home: SearchPage(searchApi: api)));

    await tester.enterText(find.byType(TextField), 'vợt');
    await tester.pump(const Duration(milliseconds: 499));
    expect(api.callCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(api.callCount, 1);
    expect(api.lastQuery, 'vợt');
    expect(find.text('Vợt cầu lông'), findsOneWidget);
  });
}
