import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/help/data/help_api.dart';
import 'package:san_va_cau_app/features/help/models/help_content.dart';
import 'package:san_va_cau_app/features/help/pages/static_page_detail_page.dart';
import 'package:san_va_cau_app/features/support/data/support_api.dart';
import 'package:san_va_cau_app/features/support/models/support_ticket.dart';
import 'package:san_va_cau_app/features/support/pages/support_ticket_detail_page.dart';
import 'package:san_va_cau_app/features/support/pages/support_ticket_list_page.dart';

class _FakeSupportApi extends SupportApi {
  _FakeSupportApi(this.ticket);

  final SupportTicket ticket;
  int listCalls = 0;
  int detailCalls = 0;
  int messageCalls = 0;

  @override
  Future<List<SupportTicket>> getMyTickets() async {
    listCalls++;
    return [ticket];
  }

  @override
  Future<SupportTicket> getTicket(String id) async {
    detailCalls++;
    return ticket;
  }

  @override
  Future<SupportTicketMessage> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    messageCalls++;
    return SupportTicketMessage(
      id: '2',
      ticketId: ticketId,
      senderId: 'customer',
      message: message,
      isStaff: false,
      createdAt: DateTime(2026, 10, 11),
    );
  }
}

class _FakeHelpApi extends HelpApi {
  @override
  Future<StaticPageDetail> getPageBySlug(String slug) async {
    return StaticPageDetail(
      slug: slug,
      title: 'Chính sách bảo mật',
      summary: 'Thông tin quan trọng',
      content: 'Nội dung chính sách được tải từ máy chủ.',
      type: 'POLICY',
    );
  }
}

SupportTicket _ticket({String status = 'OPEN'}) => SupportTicket(
  id: '42',
  subject: 'Cần hỗ trợ đơn hàng',
  message: 'Đơn hàng chưa cập nhật.',
  category: 'ORDER',
  status: status,
  priority: 'NORMAL',
  createdAt: DateTime(2026, 10, 10),
  updatedAt: DateTime(2026, 10, 11),
);

void main() {
  testWidgets('support list renders tickets from its data source', (
    tester,
  ) async {
    final api = _FakeSupportApi(_ticket());

    await tester.pumpWidget(
      MaterialApp(home: SupportTicketListPage(supportApi: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cần hỗ trợ đơn hàng'), findsOneWidget);
    expect(find.text('Đơn hàng chưa cập nhật.'), findsOneWidget);
    expect(api.listCalls, 1);
  });

  testWidgets('support detail sends a reply and reloads ticket', (
    tester,
  ) async {
    final api = _FakeSupportApi(_ticket());

    await tester.pumpWidget(
      MaterialApp(
        home: SupportTicketDetailPage(ticketId: '42', supportApi: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Xin kiểm tra giúp tôi');
    await tester.tap(find.byTooltip('Gửi phản hồi'));
    await tester.pumpAndSettle();

    expect(api.messageCalls, 1);
    expect(api.detailCalls, 2);
  });

  testWidgets('static policy page renders content from backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaticPageDetailPage(
          slug: 'privacy',
          fallbackTitle: 'Chính sách',
          helpApi: _FakeHelpApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.text('Thông tin quan trọng'), findsOneWidget);
    expect(
      find.text('Nội dung chính sách được tải từ máy chủ.'),
      findsOneWidget,
    );
  });
}
