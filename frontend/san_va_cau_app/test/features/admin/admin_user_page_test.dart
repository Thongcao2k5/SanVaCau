import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/data/admin_user_api.dart';
import 'package:san_va_cau_app/features/admin/models/admin_user.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_user_list_page.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';

class FakeBranchApi extends BranchApi {
  bool shouldThrow = false;
  int getBranchesCallCount = 0;
  ApiException? exceptionToThrow;

  @override
  Future<List<Branch>> getBranches() async {
    getBranchesCallCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Error');
    }
    return [
      const Branch(
        id: 'b1',
        name: 'Branch 1',
        address: '',
        openingTime: '',
        closingTime: '',
        status: 'ACTIVE',
      ),
    ];
  }
}

class FakeAdminUserApi extends AdminUserApi {
  bool shouldThrow = false;
  int createCallCount = 0;
  int getUsersCallCount = 0;
  int updateStatusCallCount = 0;
  int resetPasswordCallCount = 0;
  String? updatedStatus;
  String? updatedPassword;
  ApiException? getUsersException;
  Completer<void>? statusCompleter;
  Completer<void>? passwordCompleter;

  final List<AdminUser> mockUsers = [
    AdminUser(
      id: '1',
      email: 'staff@test.com',
      fullName: 'Staff 1',
      role: 'STAFF',
      status: 'ACTIVE',
      branchId: 'b1',
      mustChangePassword: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdminUser(
      id: '2',
      email: 'manager@test.com',
      fullName: 'Manager 1',
      role: 'BRANCH_MANAGER',
      status: 'LOCKED',
      branchId: 'b1',
      mustChangePassword: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdminUser(
      id: '3',
      email: 'customer@test.com',
      fullName: 'Customer 1',
      role: 'CUSTOMER',
      status: 'ACTIVE',
      branchId: null,
      mustChangePassword: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdminUser(
      id: '4',
      email: 'admin@test.com',
      fullName: 'Admin 1',
      role: 'ADMIN',
      status: 'ACTIVE',
      branchId: null,
      mustChangePassword: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<AdminUser>> getUsers({int page = 1, int limit = 100}) async {
    getUsersCallCount++;
    if (getUsersException != null) throw getUsersException!;
    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Server Error');
    }
    return mockUsers;
  }

  @override
  Future<AdminUser> createUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
    required String branchId,
  }) async {
    if (email == 'conflict@test.com') {
      throw const ApiException(statusCode: 409, message: 'Conflict');
    }
    createCallCount++;
    return mockUsers.first;
  }

  @override
  Future<AdminUser> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    updateStatusCallCount++;
    updatedStatus = status;
    await statusCompleter?.future;
    return mockUsers.first;
  }

  @override
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    resetPasswordCallCount++;
    updatedPassword = newPassword;
    await passwordCompleter?.future;
  }
}

void main() {
  group('AdminUserListPage Tests', () {
    late FakeAdminUserApi userApi;
    late FakeBranchApi branchApi;

    setUp(() {
      userApi = FakeAdminUserApi();
      branchApi = FakeBranchApi();
    });

    Widget createWidget({String role = 'ADMIN'}) {
      return MaterialApp(
        home: AdminUserListPage(
          role: role,
          userApi: userApi,
          branchApi: branchApi,
        ),
      );
    }

    testWidgets('Non-admin role cannot access', (tester) async {
      await tester.pumpWidget(createWidget(role: 'STAFF'));
      expect(find.text('Không có quyền truy cập'), findsOneWidget);
      expect(userApi.getUsersCallCount, 0);
      expect(branchApi.getBranchesCallCount, 0);
    });

    testWidgets('empty state remains pull-to-refreshable and reloads APIs', (
      tester,
    ) async {
      userApi.mockUsers.clear();
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy tài khoản nào.'), findsOneWidget);
      expect(userApi.getUsersCallCount, 1);
      expect(branchApi.getBranchesCallCount, 1);

      await tester.drag(find.byType(ListView).last, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(userApi.getUsersCallCount, 2);
      expect(branchApi.getBranchesCallCount, 2);
    });

    testWidgets('Shows loading, filters out non-staff, formats correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Should not see Customer or Admin
      expect(find.textContaining('Customer'), findsNothing);
      expect(find.textContaining('Admin 1'), findsNothing);

      // Should see Staff and Manager
      expect(find.textContaining('Staff 1'), findsOneWidget);
      expect(find.textContaining('Manager 1'), findsOneWidget);

      // Shows Branch 1
      expect(find.textContaining('Branch 1'), findsWidgets);

      // Role filter check
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhân viên').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Staff 1'), findsOneWidget);
      expect(find.textContaining('Manager 1'), findsNothing);
    });

    testWidgets('Error state and retry', (tester) async {
      userApi.shouldThrow = true;
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Lỗi tải dữ liệu'), findsOneWidget);

      userApi.shouldThrow = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Staff 1'), findsOneWidget);
    });

    testWidgets('API errors display their clean message', (tester) async {
      userApi.getUsersException = const ApiException(
        statusCode: 403,
        message: 'Bạn không có quyền thực hiện thao tác này.',
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Bạn không có quyền thực hiện thao tác này.'),
        findsOneWidget,
      );
      expect(find.textContaining('ApiException('), findsNothing);
    });

    testWidgets('Action bottom sheet allows status change and password reset', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on Manager's more_vert to open bottom sheet (manager is LOCKED)
      final moreButtons = find.byIcon(Icons.more_vert);
      await tester.tap(moreButtons.last);
      await tester.pumpAndSettle();

      expect(
        find.text('Kích hoạt'),
        findsOneWidget,
      ); // Because manager is LOCKED
      expect(find.text('Khóa tài khoản'), findsNothing); // Already locked

      // Tap Kích hoạt
      await tester.tap(find.text('Kích hoạt'));
      await tester.pumpAndSettle();

      // Dialog shows up
      expect(
        find.textContaining('thay đổi trạng thái thành Hoạt động'),
        findsOneWidget,
      );
      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();

      expect(userApi.updatedStatus, 'ACTIVE');
      expect(find.byType(SnackBar), findsOneWidget); // Success snackbar

      // Tap again for password reset
      await tester.tap(moreButtons.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đặt lại mật khẩu'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu mới *'), findsOneWidget);

      // Enter short password
      await tester.enterText(find.byType(TextFormField).first, '123');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu phải từ 6 ký tự'), findsOneWidget);

      // Enter mismatched password
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.enterText(find.byType(TextFormField).last, '1234567');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu không khớp'), findsOneWidget);

      // Enter correct
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(userApi.updatedPassword, '123456');
    });

    testWidgets('status update cannot submit a second request while pending', (
      tester,
    ) async {
      userApi.statusCompleter = Completer<void>();
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      Future<void> requestStatusChange() async {
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Khóa tài khoản'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đồng ý'));
        await tester.pump();
      }

      await requestStatusChange();
      expect(userApi.updateStatusCallCount, 1);
      await requestStatusChange();
      expect(userApi.updateStatusCallCount, 1);

      userApi.statusCompleter!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('password reset cannot submit twice or dismiss while pending', (
      tester,
    ) async {
      userApi.passwordCompleter = Completer<void>();
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.enterText(find.byType(TextFormField).last, '123456');

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Xác nhận'),
      );
      submitButton.onPressed!.call();
      submitButton.onPressed!.call();
      await tester.pump();

      expect(userApi.resetPasswordCallCount, 1);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Mật khẩu mới *'), findsOneWidget);

      userApi.passwordCompleter!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu mới *'), findsNothing);
    });

    testWidgets('Floating action button opens create form', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Thêm tài khoản'),
        findsWidgets,
      ); // App bar title of form and submit button

      // Empty submit shows validation
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(ElevatedButton, 'Thêm tài khoản');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Vui lòng nhập họ tên', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng nhập email', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng chọn vai trò', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng chọn chi nhánh', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Mật khẩu phải từ 6 ký tự', skipOffstage: false),
        findsOneWidget,
      );
      expect(userApi.createCallCount, 0);
    });

    testWidgets('create form rejects invalid email and mismatched password', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test Staff');
      await tester.enterText(fields.at(1), 'invalid-email');
      await tester.enterText(fields.at(3), '123456');
      await tester.enterText(fields.at(4), '654321');

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhân viên').last);
      await tester.pumpAndSettle();
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch 1').last);
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Thêm tài khoản',
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Email không hợp lệ', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Mật khẩu không khớp', skipOffstage: false),
        findsOneWidget,
      );
      expect(userApi.createCallCount, 0);
    });

    testWidgets('create form displays branch API errors cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      branchApi.exceptionToThrow = const ApiException(
        statusCode: 500,
        message: 'Không thể tải danh sách chi nhánh.',
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Không thể tải danh sách chi nhánh.'),
        findsOneWidget,
      );
      expect(find.textContaining('ApiException('), findsNothing);
    });
  });
}
