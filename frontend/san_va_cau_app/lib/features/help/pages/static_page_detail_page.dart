import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_page_components.dart';
import '../data/help_api.dart';
import '../models/help_content.dart';

class StaticPageDetailPage extends StatefulWidget {
  const StaticPageDetailPage({
    required this.slug,
    required this.fallbackTitle,
    this.helpApi,
    super.key,
  });

  final String slug;
  final String fallbackTitle;
  final HelpApi? helpApi;

  @override
  State<StaticPageDetailPage> createState() => _StaticPageDetailPageState();
}

class _StaticPageDetailPageState extends State<StaticPageDetailPage> {
  late final HelpApi _helpApi;
  late Future<StaticPageDetail> _pageFuture;

  @override
  void initState() {
    super.initState();
    _helpApi = widget.helpApi ?? HelpApi();
    _pageFuture = _helpApi.getPageBySlug(widget.slug);
  }

  void _load() {
    setState(() {
      _pageFuture = _helpApi.getPageBySlug(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fallbackTitle)),
      body: FutureBuilder<StaticPageDetail>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AppStateView(
              icon: Icons.error_outline_rounded,
              title: 'Chưa thể tải nội dung',
              message: error is ApiException
                  ? error.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              actionLabel: 'Thử lại',
              onAction: _load,
            );
          }

          final page = snapshot.data;
          if (page == null) return const SizedBox.shrink();

          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                AppPageIntro(
                  icon: _pageIcon(page.type),
                  title: page.title,
                  subtitle: page.summary?.trim().isNotEmpty == true
                      ? page.summary!
                      : 'Thông tin chính thức từ Sân Và Cầu.',
                ),
                const SizedBox(height: 16),
                AppSectionSurface(
                  child: Text(
                    page.content,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(height: 1.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _pageIcon(String type) {
    return switch (type) {
      'TERMS' => Icons.gavel_outlined,
      'PRIVACY' => Icons.privacy_tip_outlined,
      'RETURN_POLICY' => Icons.assignment_return_outlined,
      'PAYMENT_GUIDE' => Icons.payments_outlined,
      'BOOKING_GUIDE' => Icons.calendar_month_outlined,
      'WARRANTY' => Icons.verified_user_outlined,
      _ => Icons.description_outlined,
    };
  }
}
