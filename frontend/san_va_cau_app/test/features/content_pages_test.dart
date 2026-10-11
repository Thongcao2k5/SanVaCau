import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';
import 'package:san_va_cau_app/features/branches/pages/branch_list_page.dart';
import 'package:san_va_cau_app/features/news/data/news_api.dart';
import 'package:san_va_cau_app/features/news/models/news_article.dart';
import 'package:san_va_cau_app/features/news/pages/news_detail_page.dart';
import 'package:san_va_cau_app/features/racket_services/data/racket_service_api.dart';
import 'package:san_va_cau_app/features/racket_services/models/branch_racket_service.dart';
import 'package:san_va_cau_app/features/racket_services/pages/racket_service_page.dart';

class _FakeBranchApi extends BranchApi {
  @override
  Future<List<Branch>> getBranches() async => const [_branch];
}

class _FakeNewsApi extends NewsApi {
  @override
  Future<NewsArticle> getNewsById(String id) async => NewsArticle(
    id: id,
    title: 'Giải cầu lông cuối tuần',
    summary: 'Thông tin giải đấu',
    content: 'Đăng ký tham gia tại quầy lễ tân.',
    thumbnailUrl: '',
    publishedAt: DateTime(2026, 10, 11),
  );
}

class _FakeRacketServiceApi extends RacketServiceApi {
  @override
  Future<List<BranchRacketService>> getAvailableServices(
    String branchId,
  ) async => const [
    BranchRacketService(
      id: 'branch-service-1',
      branchId: 'branch-1',
      serviceId: 'service-1',
      referencePrice: 50000,
      estimatedDuration: '30 phút',
      service: RacketServiceInfo(
        id: 'service-1',
        name: 'Căng vợt cầu lông',
        description: 'Căng dây theo mức cân yêu cầu',
      ),
    ),
  ];
}

const _branch = Branch(
  id: 'branch-1',
  name: 'Cơ sở Quận 1',
  address: '123 Nguyễn Huệ',
  openingTime: '06:00',
  closingTime: '22:00',
  status: 'ACTIVE',
);

void main() {
  testWidgets('branch list renders branches from its data source', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BranchListPage(branchApi: _FakeBranchApi())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cơ sở Quận 1'), findsOneWidget);
    expect(find.text('123 Nguyễn Huệ'), findsOneWidget);
  });

  testWidgets('news detail renders article returned by backend data source', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsDetailPage(newsId: '7', newsApi: _FakeNewsApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giải cầu lông cuối tuần'), findsOneWidget);
    expect(find.text('Đăng ký tham gia tại quầy lễ tân.'), findsOneWidget);
  });

  testWidgets('racket service page renders services for selected branch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RacketServicePage(
          branchApi: _FakeBranchApi(),
          serviceApi: _FakeRacketServiceApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Căng vợt cầu lông'), findsOneWidget);
    expect(find.text('50.000 đ'), findsOneWidget);
    expect(find.text('30 phút'), findsOneWidget);
  });
}
