import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/widgets/app_image.dart';

void main() {
  Widget app(String source) => MaterialApp(
    home: AppImage(source: source, fallback: const SizedBox.shrink()),
  );

  testWidgets('keeps bundled asset paths as AssetImage', (tester) async {
    await tester.pumpWidget(app('assets/demo/product-shoes.jpg'));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
  });

  testWidgets('resolves relative backend media paths before loading', (
    tester,
  ) async {
    await tester.pumpWidget(app('/uploads/product.png'));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, endsWith('/uploads/product.png'));
  });
}
