import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.responseHandler);
  final Future<Map<String, dynamic>> Function(
    String method,
    String path, {
    String? token,
    Object? body,
    Map<String, String>? queryParameters,
  })
  responseHandler;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) {
    return responseHandler(
      'GET',
      path,
      token: token,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    String? token,
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    return responseHandler(
      'PATCH',
      path,
      token: token,
      body: body,
      queryParameters: queryParameters,
    );
  }
}

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage(this.token);
  final String? token;

  @override
  Future<String?> readToken() async => token;
}

void main() {
  group('AdminBookingApi', () {
    test('requires a token for admin methods', () async {
      final api = BookingApi(
        apiClient: _FakeApiClient(
          (_, _, {body, queryParameters, token}) async => {},
        ),
        tokenStorage: _FakeTokenStorage(null),
      );

      expect(() => api.getAdminBookings(), throwsA(isA<ApiException>()));
      expect(
        () => api.updateAdminBookingStatus(id: '1', status: 'CHECKED_IN'),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'getAdminBookings sends token and formatted query parameters',
      () async {
        String? requestToken;
        Map<String, String>? requestQuery;

        final api = BookingApi(
          apiClient: _FakeApiClient((
            method,
            path, {
            body,
            queryParameters,
            token,
          }) async {
            requestToken = token;
            requestQuery = queryParameters;
            return {
              'data': {'bookings': []},
            };
          }),
          tokenStorage: _FakeTokenStorage('fake-token'),
        );

        await api.getAdminBookings(
          branchId: '2 ',
          courtId: ' 3',
          date: '2026-10-06 ',
          status: ' booked ',
        );

        expect(requestToken, 'fake-token');
        expect(requestQuery?['branchId'], '2');
        expect(requestQuery?['courtId'], '3');
        expect(requestQuery?['date'], '2026-10-06');
        expect(requestQuery?['status'], 'BOOKED');
      },
    );

    test('getAdminBookings parses complex booking correctly including nullable customer and timestamps', () async {
      final api = BookingApi(
        apiClient: _FakeApiClient((_, _, {body, queryParameters, token}) async {
          return {
            'data': {
              'bookings': [
                {
                  'id': '10',
                  'bookingDate': '2026-10-06T00:00:00Z',
                  'status': 'COMPLETED',
                  'totalAmount': '500000',
                  'paymentMethod': 'BANK_TRANSFER',
                  'paymentStatus': 'PAID',
                  'createdAt': '2026-10-01T10:00:00Z',
                  'checkedInAt': '2026-10-06T10:00:00Z',
                  'completedAt': '2026-10-06T11:00:00Z',
                  'customer': {
                    'id': '99',
                    'fullName': 'John Doe',
                    'phone': '0123456789',
                  },
                  'branch': {'id': '1', 'name': 'Chi nhánh 1'},
                  'court': {'id': '2', 'name': 'Sân 2'},
                  'slots': [
                    {
                      'id': '1',
                      'timeSlotId': '2',
                      'startTime': '10:00:00',
                      'endTime': '11:00:00',
                      'priceAtBooking': '500000',
                    },
                  ],
                },
                {
                  'id': '11',
                  'status': 'BOOKED',
                  'totalAmount': '200000',
                  'branch': {'id': '1', 'name': 'Chi nhánh 1'},
                  'court': {'id': '2', 'name': 'Sân 2'},
                  // Missing dates and customer
                },
              ],
            },
          };
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      final bookings = await api.getAdminBookings();
      expect(bookings.length, 2);

      final b1 = bookings[0];
      expect(b1.id, '10');
      expect(b1.status, 'COMPLETED');
      expect(b1.createdAt?.year, 2026);
      expect(b1.checkedInAt?.year, 2026);
      expect(b1.completedAt?.year, 2026);
      expect(b1.cancelledAt, null);

      expect(b1.customer?.fullName, 'John Doe');
      expect(b1.branch.name, 'Chi nhánh 1');
      expect(b1.slots.first.startTime, '10:00:00');

      final b2 = bookings[1];
      expect(b2.id, '11');
      expect(b2.customer, null);
      expect(b2.bookingDate, null);
      expect(b2.createdAt, null);
    });

    test('updateAdminBookingStatus uses correct path, body and parses response.data directly', () async {
      String? requestPath;
      Object? requestBody;
      final api = BookingApi(
        apiClient: _FakeApiClient((
          method,
          path, {
          body,
          queryParameters,
          token,
        }) async {
          requestPath = path;
          requestBody = body;
          return {
            'success': true,
            'message': 'Status updated',
            'data': {
              'id': '42',
              'status': 'CHECKED_IN',
              'totalAmount': '100',
              'branch': {'id': '1', 'name': 'Chi nhánh 1'},
              'court': {'id': '2', 'name': 'Sân 2'},
              'createdAt': '2026-10-06T10:00:00Z',
            },
          };
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      final booking = await api.updateAdminBookingStatus(
        id: ' 42 ',
        status: ' checked_in ',
      );
      expect(requestPath, '/bookings/42/status');
      expect(requestBody, {'status': 'CHECKED_IN'});
      expect(booking.status, 'CHECKED_IN');
      expect(booking.id, '42');
    });

    test('propagates ApiException correctly', () async {
      final api = BookingApi(
        apiClient: _FakeApiClient((_, _, {body, queryParameters, token}) async {
          throw const ApiException(statusCode: 400, message: 'Status invalid');
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      expect(
        () => api.updateAdminBookingStatus(id: '1', status: 'INVALID'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
