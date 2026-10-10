import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/cart/widgets/cart_badge.dart';
import 'package:san_va_cau_app/features/cart/data/cart_updates.dart';

void main() {
  testWidgets('badge immediately reflects cart quantity changes', (
    tester,
  ) async {
    CartUpdates.quantity.value = 0;
    addTearDown(() => CartUpdates.quantity.value = 0);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CartBadge())),
    );
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    CartUpdates.quantity.value = 1;
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    CartUpdates.quantity.value = 2;
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    CartUpdates.quantity.value = 0;
    await tester.pump();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });
}
