import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/addresses/data/address_api.dart';
import 'package:san_va_cau_app/features/addresses/models/customer_address.dart';
import 'package:san_va_cau_app/features/addresses/pages/address_form_page.dart';
import 'package:san_va_cau_app/features/addresses/pages/address_list_page.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/profile_edit_page.dart';

class _FakeAuthApi extends AuthApi {
  int updateCount = 0;
  String? submittedName;
  String? submittedPhone;

  @override
  Future<AuthUser> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    updateCount += 1;
    submittedName = fullName;
    submittedPhone = phone;
    return AuthUser(
      id: _user.id,
      email: _user.email,
      fullName: fullName,
      phone: phone,
      role: _user.role,
      status: _user.status,
    );
  }
}

class _FakeAddressApi extends AddressApi {
  _FakeAddressApi({this.addresses = const []});

  List<CustomerAddress> addresses;
  int createCount = 0;
  String? submittedRecipient;

  @override
  Future<List<CustomerAddress>> getAddresses() async => addresses;

  @override
  Future<CustomerAddress> createAddress({
    required String recipientName,
    required String phone,
    required String addressLine,
    String? ward,
    String? district,
    String? city,
    String? note,
    bool isDefault = false,
  }) async {
    createCount += 1;
    submittedRecipient = recipientName;
    return CustomerAddress(
      id: 'address-new',
      recipientName: recipientName,
      phone: phone,
      addressLine: addressLine,
      ward: ward,
      district: district,
      city: city,
      note: note,
      isDefault: isDefault,
    );
  }
}

const _user = AuthUser(
  id: 'customer-1',
  email: 'customer@example.com',
  fullName: 'Nguyễn Văn A',
  phone: '0900000000',
  role: 'CUSTOMER',
  status: 'ACTIVE',
);

const _address = CustomerAddress(
  id: 'address-1',
  recipientName: 'Nguyễn Văn A',
  phone: '0900000000',
  addressLine: '12 Lê Lợi',
  city: 'TP.HCM',
  isDefault: true,
);

void main() {
  testWidgets('profile edit submits updated name and phone', (tester) async {
    final authApi = _FakeAuthApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileEditPage(user: _user, authApi: authApi),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nguyễn Văn B');
    await tester.enterText(fields.at(2), '0911111111');
    await tester.scrollUntilVisible(
      find.text('Lưu thay đổi'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(authApi.updateCount, 1);
    expect(authApi.submittedName, 'Nguyễn Văn B');
    expect(authApi.submittedPhone, '0911111111');
  });

  testWidgets('address selection page returns an existing address', (
    tester,
  ) async {
    final api = _FakeAddressApi(addresses: [_address]);
    CustomerAddress? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<CustomerAddress>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddressListPage(selectionMode: true, addressApi: api),
                  ),
                );
              },
              child: const Text('Mở địa chỉ'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở địa chỉ'));
    await tester.pumpAndSettle();
    expect(find.text('Nơi nhận quen thuộc'), findsNothing);
    await tester.tap(find.text('Nguyễn Văn A'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'address-1');
  });

  testWidgets('normal address list uses the account visual hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddressListPage(
          addressApi: _FakeAddressApi(addresses: [_address]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nơi nhận quen thuộc'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Thêm địa chỉ'), findsNothing);
  });

  testWidgets('address form validates and creates an address', (tester) async {
    final api = _FakeAddressApi();
    await tester.pumpWidget(
      MaterialApp(home: AddressFormPage(addressApi: api)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Lưu địa chỉ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lưu địa chỉ'));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên người nhận'), findsOneWidget);
    expect(api.createCount, 0);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nguyễn Văn A');
    await tester.enterText(fields.at(1), '0900000000');
    await tester.enterText(fields.at(2), '12 Lê Lợi');
    await tester.scrollUntilVisible(
      find.text('Lưu địa chỉ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lưu địa chỉ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.createCount, 1);
    expect(api.submittedRecipient, 'Nguyễn Văn A');
  });
}
