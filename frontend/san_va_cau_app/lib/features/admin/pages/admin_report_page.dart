import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_report_api.dart';
import '../models/admin_report.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({
    super.key,
    required this.role,
    this.branchId,
    this.api,
  });

  final String role;
  final String? branchId;
  final AdminReportApi? api;

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  late final AdminReportApi _api;
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  String? _errorMessage;

  AdminReportOverview? _overview;
  List<AdminReportTopProduct>? _topProducts;
  List<AdminReportTopCourt>? _topCourts;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AdminReportApi();

    if (widget.role != 'ADMIN' &&
        widget.role != 'BRANCH_MANAGER' &&
        widget.role != 'STAFF') {
      _errorMessage = 'Bạn không có quyền truy cập';
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      setState(() {
        _errorMessage = 'Ngày bắt đầu phải trước ngày kết thúc';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fromStr = _fromDate?.toIso8601String().substring(0, 10);
      final toStr = _toDate?.toIso8601String().substring(0, 10);

      final results = await Future.wait([
        _api.getOverview(from: fromStr, to: toStr),
        _api.getTopProducts(from: fromStr, to: toStr, limit: 5),
        _api.getTopCourts(from: fromStr, to: toStr, limit: 5),
      ]);

      if (!mounted) return;

      setState(() {
        _overview = results[0] as AdminReportOverview;
        _topProducts = results[1] as List<AdminReportTopProduct>;
        _topCourts = results[2] as List<AdminReportTopCourt>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    if (_isLoading) return;

    final initialDateRange = _fromDate != null && _toDate != null
        ? DateTimeRange(start: _fromDate!, end: _toDate!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _fromDate = picked.start;
      _toDate = picked.end;
    });
    _loadData();
  }

  void _clearFilters() {
    if (_isLoading) return;
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadData();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _money(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '${buffer.toString()}đ';
  }

  @override
  Widget build(BuildContext context) {
    final hasNoAccess =
        widget.role != 'ADMIN' &&
        widget.role != 'BRANCH_MANAGER' &&
        widget.role != 'STAFF';

    if (hasNoAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo tổng hợp')),
        body: const Center(child: Text('Bạn không có quyền truy cập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo tổng hợp'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _overview == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildScopeLabel(),
          const SizedBox(height: 16),
          _buildFilterBar(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
          if (_overview != null) ...[
            const SizedBox(height: 16),
            _buildOverviewCards(_overview!),
            const SizedBox(height: 24),
            _buildTopProducts(_topProducts!),
            const SizedBox(height: 24),
            _buildTopCourts(_topCourts!),
          ],
        ],
      ),
    );
  }

  Widget _buildScopeLabel() {
    final String label;
    if (widget.role == 'ADMIN' &&
        (widget.branchId == null || widget.branchId!.isEmpty)) {
      label = 'Toàn hệ thống';
    } else {
      label = 'Chi nhánh #${widget.branchId ?? "Không rõ"}';
    }

    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildFilterBar() {
    final String dateText;
    if (_fromDate != null && _toDate != null) {
      dateText = '${_formatDate(_fromDate!)} - ${_formatDate(_toDate!)}';
    } else {
      dateText = 'Chọn ngày...';
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateText,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_fromDate != null || _toDate != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear),
            tooltip: 'Xóa bộ lọc',
          ),
        ],
      ],
    );
  }

  Widget _buildOverviewCards(AdminReportOverview data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              label: 'Tổng đơn hàng',
              value: '${data.totalOrders}',
              detail: _money(data.totalOrderRevenue),
              icon: Icons.receipt_long,
              color: AppColors.primary,
            ),
            _MetricCard(
              label: 'Lịch đặt sân',
              value: '${data.totalBookings}',
              detail: _money(data.totalBookingRevenue),
              icon: Icons.calendar_month,
              color: AppColors.info,
            ),
            _MetricCard(
              label: 'Thanh toán',
              value: '${data.totalPayments}',
              detail: _money(data.totalPaidAmount),
              icon: Icons.payments,
              color: AppColors.success,
            ),
            _MetricCard(
              label: 'Hỗ trợ & Khách',
              value: '${data.totalCustomers} khách',
              detail:
                  '${data.openSupportTickets}/${data.totalSupportTickets} hỗ trợ mở',
              icon: Icons.people,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopProducts(List<AdminReportTopProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 sản phẩm',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const _EmptyState(message: 'Không có dữ liệu sản phẩm')
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(products[i].productName),
                    subtitle: Text('Đã bán: ${products[i].totalQuantity}'),
                    trailing: Text(
                      _money(products[i].totalRevenue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (i < products.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTopCourts(List<AdminReportTopCourt> courts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 sân',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (courts.isEmpty)
          const _EmptyState(message: 'Không có dữ liệu sân')
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < courts.length; i++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(
                      '${courts[i].courtName} - ${courts[i].branchName}',
                    ),
                    subtitle: Text('Lượt đặt: ${courts[i].bookingCount}'),
                    trailing: Text(
                      _money(courts[i].totalRevenue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (i < courts.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
