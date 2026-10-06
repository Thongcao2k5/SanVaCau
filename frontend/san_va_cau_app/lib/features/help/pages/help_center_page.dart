import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/help_api.dart';
import '../models/help_content.dart';
import 'contact_page.dart';
import 'static_page_detail_page.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key, this.helpApi});

  final HelpApi? helpApi;

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  late final HelpApi _helpApi;
  late Future<HelpContent> _contentFuture;
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _helpApi = widget.helpApi ?? HelpApi();
    _contentFuture = _helpApi.getHelpContent();
  }

  Future<void> _reload() async {
    final future = _helpApi.getHelpContent();
    setState(() {
      _contentFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp')),
      body: FutureBuilder<HelpContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return _HelpState(
              icon: Icons.support_agent_outlined,
              title: 'Chưa thể tải trợ giúp',
              message: error is ApiException
                  ? error.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }

          final content =
              snapshot.data ?? const HelpContent(faqs: [], pages: []);
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ContactBanner(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContactPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (content.faqs.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Câu hỏi thường gặp',
                    subtitle: 'Chạm vào câu hỏi để xem câu trả lời.',
                  ),
                  const SizedBox(height: 12),
                  _CategoryFilter(
                    faqs: content.faqs,
                    selected: _selectedCategory,
                    onSelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 12),
                  ..._filteredFaqs(content.faqs).map(
                    (faq) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FaqCard(faq: faq),
                    ),
                  ),
                ],
                if (content.pages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    title: 'Hướng dẫn & chính sách',
                    subtitle: 'Thông tin sử dụng dịch vụ của Sân Và Cầu.',
                  ),
                  const SizedBox(height: 12),
                  ...content.pages.map(
                    (page) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PolicyTile(page: page),
                    ),
                  ),
                ],
                if (content.faqs.isEmpty && content.pages.isEmpty)
                  _HelpState(
                    icon: Icons.help_outline,
                    title: 'Chưa có nội dung trợ giúp',
                    message: 'Nội dung sẽ xuất hiện sau khi được quản trị viên đăng.',
                    actionLabel: 'Liên hệ hỗ trợ',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ContactPage(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<FaqItem> _filteredFaqs(List<FaqItem> faqs) {
    if (_selectedCategory == 'Tất cả') return faqs;
    return faqs.where((faq) => faq.category == _selectedCategory).toList();
  }
}

class _ContactBanner extends StatelessWidget {
  const _ContactBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn vẫn cần hỗ trợ?',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gửi nội dung cho đội ngũ Sân Và Cầu.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Gửi liên hệ',
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.faqs,
    required this.selected,
    required this.onSelected,
  });

  final List<FaqItem> faqs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = <String>{'Tất cả', ...faqs.map((faq) => faq.category)};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.faq});

  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.help_outline, color: AppColors.primary),
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({required this.page});

  final StaticPageSummary page;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 64,
        leading: Icon(_pageIcon(page.type), color: AppColors.primary),
        title: Text(
          page.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: page.summary == null || page.summary!.trim().isEmpty
            ? null
            : Text(page.summary!, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StaticPageDetailPage(
              slug: page.slug,
              fallbackTitle: page.title,
            ),
          ),
        ),
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
      'ABOUT' => Icons.info_outline,
      _ => Icons.description_outlined,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _HelpState extends StatelessWidget {
  const _HelpState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
