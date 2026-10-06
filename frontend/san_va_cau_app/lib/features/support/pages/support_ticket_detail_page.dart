import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/support_api.dart';
import '../models/support_ticket.dart';
import '../support_display.dart';

class SupportTicketDetailPage extends StatefulWidget {
  const SupportTicketDetailPage({required this.ticketId, super.key});

  final String ticketId;

  @override
  State<SupportTicketDetailPage> createState() =>
      _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState extends State<SupportTicketDetailPage> {
  final SupportApi _supportApi = SupportApi();
  final TextEditingController _messageController = TextEditingController();
  late Future<SupportTicket> _ticketFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _ticketFuture = _supportApi.getTicket(widget.ticketId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _supportApi.getTicket(widget.ticketId);
    setState(() => _ticketFuture = future);
    await future;
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await _supportApi.sendMessage(
        ticketId: widget.ticketId,
        message: message,
      );
      _messageController.clear();
      await _reload();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yêu cầu #${widget.ticketId}')),
      body: FutureBuilder<SupportTicket>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            final error = snapshot.error;
            return _DetailState(
              message: error is ApiException
                  ? error.message
                  : 'Không thể tải yêu cầu hỗ trợ.',
              onRetry: _reload,
            );
          }

          final ticket = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _TicketHeader(ticket: ticket),
                      const SizedBox(height: 20),
                      Text(
                        'Trao đổi',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      if (ticket.messages.isEmpty)
                        _MessageBubble(
                          message: ticket.message,
                          sender: 'Bạn',
                          timestamp: ticket.createdAt,
                          isStaff: false,
                        )
                      else
                        ...ticket.messages.map(
                          (message) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MessageBubble(
                              message: message.message,
                              sender: message.isStaff
                                  ? (message.senderName ?? 'Nhân viên hỗ trợ')
                                  : 'Bạn',
                              timestamp: message.createdAt,
                              isStaff: message.isStaff,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _MessageComposer(
                controller: _messageController,
                enabled: ticket.canReply && !_isSending,
                isSending: _isSending,
                isClosed: !ticket.canReply,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final statusColor = supportStatusColor(ticket.status);
    return Card(
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
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
            const SizedBox(height: 12),
            Text(
              '${supportCategoryLabel(ticket.category)} · Ưu tiên ${supportPriorityLabel(ticket.priority).toLowerCase()}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Cập nhật ${formatSupportDate(ticket.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.sender,
    required this.timestamp,
    required this.isStaff,
  });

  final String message;
  final String sender;
  final DateTime timestamp;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isStaff ? AppColors.surfaceMuted : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 6),
              Text(
                formatSupportDate(timestamp),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.isClosed,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final bool isClosed;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderMuted)),
        ),
        child: isClosed
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Yêu cầu này đã đóng'),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Nhập phản hồi...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Gửi phản hồi',
                    onPressed: enabled ? onSend : null,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailState extends StatelessWidget {
  const _DetailState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
