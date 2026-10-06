import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/support/models/support_ticket.dart';

void main() {
  test('parses support ticket and nested messages', () {
    final ticket = SupportTicket.fromJson({
      'id': '12',
      'subject': 'Hỗ trợ đơn hàng',
      'message': 'Tôi cần hỗ trợ',
      'category': 'ORDER',
      'status': 'OPEN',
      'priority': 'HIGH',
      'targetType': 'ORDER',
      'targetId': '7',
      'createdAt': '2026-10-06T02:00:00.000Z',
      'updatedAt': '2026-10-06T03:00:00.000Z',
      'messages': [
        {
          'id': '31',
          'ticketId': '12',
          'senderId': '118',
          'senderName': 'Khách hàng',
          'senderRole': 'CUSTOMER',
          'message': 'Tôi cần hỗ trợ',
          'isStaff': false,
          'createdAt': '2026-10-06T02:00:00.000Z',
        },
      ],
    });

    expect(ticket.id, '12');
    expect(ticket.category, 'ORDER');
    expect(ticket.priority, 'HIGH');
    expect(ticket.canReply, isTrue);
    expect(ticket.messages, hasLength(1));
    expect(ticket.messages.single.message, 'Tôi cần hỗ trợ');
    expect(ticket.messages.single.isStaff, isFalse);
  });

  test('closed support ticket cannot receive a reply', () {
    final ticket = SupportTicket.fromJson({
      'id': '13',
      'status': 'CLOSED',
      'createdAt': 'invalid',
      'updatedAt': 'invalid',
    });

    expect(ticket.canReply, isFalse);
    expect(ticket.messages, isEmpty);
  });
}
