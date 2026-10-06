import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/help_api.dart';
import '../models/help_content.dart';

class StaticPageDetailPage extends StatefulWidget {
  const StaticPageDetailPage({
    required this.slug,
    required this.fallbackTitle,
    super.key,
  });

  final String slug;
  final String fallbackTitle;

  @override
  State<StaticPageDetailPage> createState() => _StaticPageDetailPageState();
}

class _StaticPageDetailPageState extends State<StaticPageDetailPage> {
  final HelpApi _helpApi = HelpApi();
  late Future<StaticPageDetail> _pageFuture;

  @override
  void initState() {
    super.initState();
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 44,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error is ApiException
                          ? error.message
                          : 'Không thể tải nội dung.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final page = snapshot.data;
          if (page == null) return const SizedBox.shrink();

          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (page.summary != null &&
                    page.summary!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    page.summary!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const Divider(height: 32),
                ] else
                  const SizedBox(height: 20),
                Text(
                  page.content,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(height: 1.65),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
