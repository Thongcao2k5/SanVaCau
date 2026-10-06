import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/support_api.dart';
import '../models/support_ticket.dart';
import '../support_display.dart';
import 'support_ticket_detail_page.dart';
import 'support_ticket_form_page.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage> {
  final SupportApi _supportApi = SupportApi();
  late Future<List<SupportTicket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _supportApi.getMyTickets();
  }

  Future<void> _reload() async {
    final future = _supportApi.getMyTickets();
    setState(() => _ticketsFuture = future);
    await future;
  }

  Future<void> _createTicket() async {
    final ticket = await Navigator.of(context).push<SupportTicket>(
      MaterialPageRoute(builder: (_) => const SupportTicketFormPage()),
    );
    if (ticket == null || !mounted) return;
    await _reload();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SupportTicketDetailPage(ticketId: ticket.id),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SupportTicketDetailPage(ticketId: ticket.id),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu hỗ trợ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket,
        icon: const Icon(Icons.add),
        label: const Text('Tạo yêu cầu'),
      ),
      body: FutureBuilder<List<SupportTicket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _TicketListState(
              icon: Icons.support_agent_outlined,
              title: 'Chưa thể tải yêu cầu',
              message: error is ApiException
                  ? error.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }

          final tickets = snapshot.data ?? const [];
          if (tickets.isEmpty) {
            return _TicketListState(
              icon: Icons.mark_email_unread_outlined,
              title: 'Chưa có yêu cầu hỗ trợ',
              message: 'Tạo yêu cầu khi bạn cần trợ giúp về đơn hàng, đặt sân hoặc tài khoản.',
              actionLabel: 'Tạo yêu cầu',
              onAction: _createTicket,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _TicketCard(
                  ticket: ticket,
                  onTap: () => _openTicket(ticket),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = supportStatusColor(ticket.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      supportStatusLabel(ticket.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.label_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    supportCategoryLabel(ticket.category),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    formatSupportDate(ticket.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketListState extends StatelessWidget {
  const _TicketListState({
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
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primary),
            const SizedBox(height: 14),
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
