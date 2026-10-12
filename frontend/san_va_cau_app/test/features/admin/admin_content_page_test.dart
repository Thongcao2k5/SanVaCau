import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';
import 'package:san_va_cau_app/features/admin/widgets/admin_ui.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/data/admin_content_api.dart';
import 'package:san_va_cau_app/features/admin/data/admin_user_api.dart';
import 'package:san_va_cau_app/features/admin/models/admin_content.dart';
import 'package:san_va_cau_app/features/admin/models/admin_user.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_banner_list_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_content_hub_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_news_list_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_notification_form_page.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';
import 'package:san_va_cau_app/features/notifications/models/notification_item.dart';

AdminNewsArticle _news({String status = 'PUBLISHED'}) => AdminNewsArticle(
  id: '1',
  title: 'Tin kiểm thử',
  summary: 'Tóm tắt',
  content: 'Nội dung',
  thumbnailUrl: '',
  publishedAt: null,
  status: status,
  authorName: 'Admin',
);

AdminBanner _banner({bool isActive = true}) => AdminBanner(
  id: '1',
  title: 'Banner kiểm thử',
  imageUrl: '',
  sortOrder: 1,
  isActive: isActive,
);

NotificationItem _notification() => NotificationItem(
  id: '1',
  type: 'SYSTEM',
  title: 'Thông báo',
  message: 'Nội dung',
  isRead: false,
  createdAt: DateTime(2026, 10, 6),
);

class _FakeAdminContentApi extends Fake implements AdminContentApi {
  List<AdminNewsArticle> news = [];
  List<AdminBanner> banners = [];
  ApiException? loadError;
  Completer<AdminNewsArticle>? createNewsCompleter;
  Completer<AdminBanner>? inactivateBannerCompleter;
  Completer<NotificationItem>? sendNotificationCompleter;
  Completer<AdminBanner>? createBannerCompleter;

  int getNewsCalls = 0;
  int getBannerCalls = 0;
  int createNewsCalls = 0;
  int inactivateBannerCalls = 0;
  int sendNotificationCalls = 0;
  int createBannerCalls = 0;

  @override
  Future<AdminBanner> createBanner({
    String? title,
    required String imageUrl,
    String? linkUrl,
    int sortOrder = 0,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    createBannerCalls++;
    return createBannerCompleter?.future ?? Future.value(_banner());
  }

  final List<String> requestedStatuses = [];

  @override
  Future<List<AdminNewsArticle>> getNews({
    required String status,
    int limit = 50,
  }) async {
    getNewsCalls++;
    requestedStatuses.add(status);
    if (loadError != null) throw loadError!;
    return news.where((item) => item.status == status).toList();
  }

  @override
  Future<List<AdminBanner>> getBanners() async {
    getBannerCalls++;
    if (loadError != null) throw loadError!;
    return banners;
  }

  @override
  Future<AdminNewsArticle> createNews({
    required String title,
    required String content,
    String? summary,
    String? thumbnailUrl,
    String? branchId,
  }) {
    createNewsCalls++;
    return createNewsCompleter?.future ?? Future.value(_news(status: 'DRAFT'));
  }

  @override
  Future<AdminBanner> inactivateBanner(String id) {
    inactivateBannerCalls++;
    return inactivateBannerCompleter?.future ??
        Future.value(_banner(isActive: false));
  }

  @override
  Future<NotificationItem> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) {
    sendNotificationCalls++;
    return sendNotificationCompleter?.future ?? Future.value(_notification());
  }
}

class _FakeAdminUserApi extends Fake implements AdminUserApi {
  _FakeAdminUserApi({this.fullName = 'Khách hàng'});
  final String fullName;
  int getUsersCalls = 0;

  @override
  Future<List<AdminUser>> getUsers({int page = 1, int limit = 100}) async {
    getUsersCalls++;
    return [
      AdminUser(
        id: '1',
        email: 'customer@example.com',
        fullName: fullName,
        phone: '',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        branchId: null,
        mustChangePassword: false,
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      ),
    ];
  }
}

class _FakeBranchApi extends Fake implements BranchApi {
  int getBranchesCalls = 0;

  @override
  Future<List<Branch>> getBranches() async {
    getBranchesCalls++;
    return [];
  }
}

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light(), home: child);

Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  double delta = 180,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _selectRecipient(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String?>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Khách hàng (CUSTOMER)').last);
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 800),
    const Size(375, 800),
    const Size(800, 375),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'all content pages and keyboard forms at $size, scale $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final api = _FakeAdminContentApi()
            ..news = [_news()]
            ..banners = [_banner()];
          Widget app(Widget home, {bool keyboard = false, String key = ''}) =>
              MaterialApp(
                key: ValueKey(key),
                theme: AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 24),
                    viewInsets: keyboard
                        ? const EdgeInsets.only(bottom: 160)
                        : EdgeInsets.zero,
                  ),
                  child: child!,
                ),
                home: home,
              );
          final pages = [
            const AdminContentHubPage(role: 'ADMIN'),
            AdminNewsListPage(
              role: 'ADMIN',
              api: api,
              branchApi: _FakeBranchApi(),
            ),
            AdminBannerListPage(role: 'ADMIN', api: api),
            AdminNotificationFormPage(
              role: 'ADMIN',
              api: api,
              userApi: _FakeAdminUserApi(
                fullName: 'Người nhận với tên dài để kiểm tra bố cục',
              ),
            ),
          ];
          for (var i = 0; i < pages.length; i++) {
            await tester.pumpWidget(app(pages[i], key: '$i'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'page $i');
            if (i == 1 || i == 2) {
              await tester.tap(find.byType(FloatingActionButton));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: 'form $i');
              await _reveal(tester, find.byType(FilledButton));
              await tester.tap(find.byType(FilledButton));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: 'validation $i');
            } else {
              await tester.drag(
                find.byType(ListView).last,
                const Offset(0, -2000),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
          await tester.pumpWidget(
            app(
              AdminNotificationFormPage(
                role: 'ADMIN',
                api: api,
                userApi: _FakeAdminUserApi(),
              ),
              keyboard: true,
              key: 'keyboard',
            ),
          );
          await tester.pumpAndSettle();
          await _reveal(tester, find.bySemanticsLabel('Nội dung thông báo *'));
          await tester.enterText(
            find.bySemanticsLabel('Nội dung thông báo *'),
            'Nội dung kiểm thử',
          );
          await _reveal(tester, find.byType(FilledButton));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('content controls satisfy Android touch and label guidelines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final api = _FakeAdminContentApi()
      ..news = [_news()]
      ..banners = [_banner()];
    final pages = [
      const AdminContentHubPage(role: 'ADMIN'),
      AdminNewsListPage(role: 'ADMIN', api: api),
      AdminBannerListPage(role: 'ADMIN', api: api),
      AdminNotificationFormPage(
        role: 'ADMIN',
        api: api,
        userApi: _FakeAdminUserApi(),
      ),
    ];
    try {
      for (var i = 0; i < pages.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(i),
            theme: AppTheme.light(),
            home: pages[i],
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: 'page $i',
        );
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: 'page $i',
        );
        await expectLater(
          tester,
          meetsGuideline(textContrastGuideline),
          reason: 'page $i',
        );
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('news cards show draft, published and archived badges', (
    tester,
  ) async {
    final api = _FakeAdminContentApi()
      ..news = [_news(), _news(status: 'DRAFT'), _news(status: 'ARCHIVED')];
    await tester.pumpWidget(_app(AdminNewsListPage(role: 'ADMIN', api: api)));
    await tester.pumpAndSettle();
    for (final label in ['Đã xuất bản', 'Bản nháp', 'Lưu trữ']) {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AdminStatusBadge, label), findsOneWidget);
    }
  });

  testWidgets('banner preview follows URL and saving disables all fields', (
    tester,
  ) async {
    final completer = Completer<AdminBanner>();
    final api = _FakeAdminContentApi()..createBannerCompleter = completer;
    await tester.pumpWidget(_app(AdminBannerListPage(role: 'ADMIN', api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm banner'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có ảnh banner'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('URL Ảnh *'),
      'https://example.com/banner.jpg',
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Không thể tải ảnh banner'), findsOneWidget);
    await _reveal(tester, find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(api.createBannerCalls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.enabled, isFalse);
    }
    completer.completeError(
      const ApiException(statusCode: 500, message: 'Lưu banner thất bại'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lưu banner thất bại'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('banner deactivation can be cancelled without an API call', (
    tester,
  ) async {
    final api = _FakeAdminContentApi()..banners = [_banner()];
    await tester.pumpWidget(_app(AdminBannerListPage(role: 'ADMIN', api: api)));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byTooltip('Thao tác banner'));
    await tester.tap(find.byTooltip('Thao tác banner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy kích hoạt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(api.inactivateBannerCalls, 0);
  });

  test('banner schedule rejects equal or reversed dates', () {
    final start = DateTime(2026, 10, 7);

    expect(isValidBannerSchedule(start, start), isFalse);
    expect(
      isValidBannerSchedule(start, start.subtract(const Duration(days: 1))),
      isFalse,
    );
    expect(
      isValidBannerSchedule(start, start.add(const Duration(days: 1))),
      isTrue,
    );
    expect(isValidBannerSchedule(null, start), isTrue);
  });

  group('Admin content role guards', () {
    testWidgets('hub blocks non-ADMIN', (tester) async {
      await tester.pumpWidget(_app(const AdminContentHubPage(role: 'STAFF')));

      expect(
        find.text('Bạn không có quyền truy cập trang này.'),
        findsOneWidget,
      );
      expect(find.text('Tin tức'), findsNothing);
    });

    testWidgets('direct pages do not call APIs for non-ADMIN roles', (
      tester,
    ) async {
      final api = _FakeAdminContentApi();
      final userApi = _FakeAdminUserApi();

      await tester.pumpWidget(_app(AdminNewsListPage(role: 'STAFF', api: api)));
      await tester.pump();
      await tester.pumpWidget(
        _app(AdminBannerListPage(role: 'BRANCH_MANAGER', api: api)),
      );
      await tester.pump();
      await tester.pumpWidget(
        _app(
          AdminNotificationFormPage(role: 'STAFF', api: api, userApi: userApi),
        ),
      );
      await tester.pump();

      expect(api.getNewsCalls, 0);
      expect(api.getBannerCalls, 0);
      expect(userApi.getUsersCalls, 0);
      expect(
        find.text('Bạn không có quyền truy cập trang này.'),
        findsOneWidget,
      );
    });
  });

  group('Admin news', () {
    testWidgets('status filter reloads and empty state supports refresh', (
      tester,
    ) async {
      final api = _FakeAdminContentApi()..news = [_news()];

      await tester.pumpWidget(_app(AdminNewsListPage(role: 'ADMIN', api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Tin kiểm thử'), findsOneWidget);

      await tester.tap(find.text('Bản nháp'));
      await tester.pumpAndSettle();
      expect(api.requestedStatuses, ['PUBLISHED', 'DRAFT']);
      expect(find.text('Không có tin tức nào'), findsOneWidget);

      await tester.drag(
        find.text('Không có tin tức nào'),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(api.getNewsCalls, 3);
    });

    testWidgets('shows ApiException message without raw exception text', (
      tester,
    ) async {
      final api = _FakeAdminContentApi()
        ..loadError = const ApiException(
          statusCode: 403,
          message: 'Thông báo sạch từ backend',
        );

      await tester.pumpWidget(_app(AdminNewsListPage(role: 'ADMIN', api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Thông báo sạch từ backend'), findsOneWidget);
      expect(find.textContaining('ApiException'), findsNothing);
    });

    testWidgets('create validates fields and disables duplicate submission', (
      tester,
    ) async {
      final completer = Completer<AdminNewsArticle>();
      final api = _FakeAdminContentApi()..createNewsCompleter = completer;
      final branchApi = _FakeBranchApi();

      await tester.pumpWidget(
        _app(AdminNewsListPage(role: 'ADMIN', api: api, branchApi: branchApi)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tạo tin tức'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      final saveButton = find.byType(FilledButton);
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      expect(find.text('Không được để trống'), findsWidgets);

      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Tin mới');
      await tester.enterText(find.byType(TextFormField).at(2), 'Nội dung mới');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(api.createNewsCalls, 1);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      completer.complete(_news(status: 'DRAFT'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('pending create can be disposed safely', (tester) async {
      final completer = Completer<AdminNewsArticle>();
      final api = _FakeAdminContentApi()..createNewsCompleter = completer;

      await tester.pumpWidget(
        _app(
          AdminNewsListPage(
            role: 'ADMIN',
            api: api,
            branchApi: _FakeBranchApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Tin mới');
      await tester.enterText(find.byType(TextFormField).at(2), 'Nội dung mới');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      final saveButton = find.byType(FilledButton);
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      completer.complete(_news(status: 'DRAFT'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('Admin banners', () {
    testWidgets('empty state supports refresh', (tester) async {
      final api = _FakeAdminContentApi();

      await tester.pumpWidget(
        _app(AdminBannerListPage(role: 'ADMIN', api: api)),
      );
      await tester.pumpAndSettle();
      expect(api.getBannerCalls, 1);

      await tester.drag(
        find.text('Không có banner nào đang hoạt động'),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(api.getBannerCalls, 2);
    });

    testWidgets('create form validates image URL and integer sort order', (
      tester,
    ) async {
      final api = _FakeAdminContentApi();

      await tester.pumpWidget(
        _app(AdminBannerListPage(role: 'ADMIN', api: api)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      final saveButton = find.byType(FilledButton);
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      expect(find.text('Không được để trống'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pump();
      await tester.enterText(
        find.bySemanticsLabel('URL Ảnh *'),
        'https://example.com/banner.jpg',
      );
      await tester.enterText(find.bySemanticsLabel('Thứ tự sắp xếp'), '1.5');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Phải là số nguyên'), findsOneWidget);
    });

    testWidgets('inactivate action is locked while request is pending', (
      tester,
    ) async {
      final completer = Completer<AdminBanner>();
      final api = _FakeAdminContentApi()
        ..banners = [_banner()]
        ..inactivateBannerCompleter = completer;

      await tester.pumpWidget(
        _app(AdminBannerListPage(role: 'ADMIN', api: api)),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, find.byIcon(Icons.more_vert));
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy kích hoạt'));
      await tester.pumpAndSettle();
      expect(api.inactivateBannerCalls, 0);
      await tester.tap(find.text('Xác nhận'));
      await tester.pump();

      expect(api.inactivateBannerCalls, 1);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_banner(isActive: false));
      await tester.pumpAndSettle();
      expect(find.text('Đã hủy kích hoạt banner'), findsOneWidget);
    });
  });

  group('Admin notifications', () {
    testWidgets('validates and locks submission while sending', (tester) async {
      final completer = Completer<NotificationItem>();
      final api = _FakeAdminContentApi()..sendNotificationCompleter = completer;

      await tester.pumpWidget(
        _app(
          AdminNotificationFormPage(
            role: 'ADMIN',
            api: api,
            userApi: _FakeAdminUserApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      final sendButton = find.byType(FilledButton);
      await _reveal(tester, sendButton);
      await tester.tap(sendButton);
      await tester.pump();
      expect(find.text('Vui lòng chọn người nhận'), findsWidgets);
      expect(find.text('Không được để trống'), findsNWidgets(2));

      await _selectRecipient(tester);
      await tester.enterText(
        find.bySemanticsLabel('Tiêu đề thông báo *'),
        'Cảnh báo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Nội dung thông báo *'),
        'Nội dung',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      await _reveal(tester, sendButton);
      await tester.tap(sendButton);
      await tester.pump();

      expect(api.sendNotificationCalls, 1);
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

      completer.complete(_notification());
      await tester.pumpAndSettle();
      expect(find.text('Đã gửi thông báo thành công'), findsOneWidget);
    });
  });

  testWidgets('content hub has no overflow at 360 logical pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_app(const AdminContentHubPage(role: 'ADMIN')));
    await tester.pumpAndSettle();

    expect(find.text('Tin tức'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
