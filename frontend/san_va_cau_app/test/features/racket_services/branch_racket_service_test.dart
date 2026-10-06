import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/racket_services/models/branch_racket_service.dart';

void main() {
  test('parses an available racket service at a branch', () {
    final item = BranchRacketService.fromJson({
      'id': '9',
      'branchId': '2',
      'serviceId': '4',
      'referencePrice': '120000.00',
      'description': 'Bao gồm công căng',
      'estimatedDuration': '30 phút',
      'service': {
        'id': '4',
        'name': 'Căng vợt',
        'description': 'Căng dây theo mức cân yêu cầu',
        'imageUrl': null,
      },
    });

    expect(item.id, '9');
    expect(item.referencePrice, 120000);
    expect(item.estimatedDuration, '30 phút');
    expect(item.service.name, 'Căng vợt');
  });

  test('handles an omitted reference price', () {
    final item = BranchRacketService.fromJson({'service': <String, dynamic>{}});

    expect(item.referencePrice, isNull);
    expect(item.service.name, isEmpty);
  });
}
