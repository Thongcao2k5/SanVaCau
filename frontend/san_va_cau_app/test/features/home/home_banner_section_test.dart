import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/home/models/home_data.dart';
import 'package:san_va_cau_app/features/home/widgets/home_banner_section.dart';

void main() {
  testWidgets('renders bundled banner paths as assets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeBannerSection(
            banners: [
              HomeBanner(
                id: '1',
                title: 'Banner sân cầu',
                imageUrl: 'assets/demo/banner-court.jpg',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(find.byIcon(Icons.broken_image), findsNothing);
  });
}
