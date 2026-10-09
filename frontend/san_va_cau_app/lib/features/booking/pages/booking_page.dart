import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/pages/account_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/booking_api.dart';
import '../models/court.dart';
import '../widgets/booking_timeline.dart';
import 'court_detail_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({
    super.key,
    this.initialBranch,
    this.branchApi,
    this.bookingApi,
    this.onTimelineVisibilityChanged,
    this.authApi,
  });

  final Branch? initialBranch;
  final BranchApi? branchApi;
  final BookingApi? bookingApi;
  final ValueChanged<bool>? onTimelineVisibilityChanged;
  final AuthApi? authApi;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late final BranchApi _branchApi = widget.branchApi ?? BranchApi();
  late final BookingApi _bookingApi = widget.bookingApi ?? BookingApi();
  late Future<List<Branch>> _branchesFuture;
  Future<List<CourtSchedule>>? _scheduleFuture;
  Branch? _branch;

  DateTime _date = DateUtils.dateOnly(DateTime.now());
  final Map<String, CourtSlotSelection> _selected = {};
  bool _submitting = false;
  bool _checkingLogin = false;
  final TokenStorage _tokenStorage = TokenStorage();
  double _zoom = 1;

  String get _dateKey =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
  String get _dateLabel =>
      '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';
  double get _total =>
      _selected.values.fold(0, (sum, slot) => sum + slot.slot.price);
  String _money(double value) =>
      '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

  @override
  void initState() {
    super.initState();
    _branchesFuture = _branchApi.getBranches();
    if (widget.initialBranch != null) {
      _chooseBranch(widget.initialBranch!, notify: false);
    }
  }

  Future<List<CourtSchedule>> _loadSchedule(
    String branchId,
    String date,
  ) async {
    final courts = await _bookingApi.getCourts(branchId: branchId);
    return Future.wait(
      courts.map((court) async {
        try {
          final slots = await _bookingApi.getAvailability(
            courtId: court.id,
            date: date,
          );
          return CourtSchedule(court: court, slots: slots);
        } catch (_) {
          return CourtSchedule(court: court, slots: const [], hasError: true);
        }
      }),
    );
  }

  void _chooseBranch(Branch branch, {bool notify = true}) {
    setState(() {
      _branch = branch;

      _selected.clear();
      _scheduleFuture = _loadSchedule(branch.id, _dateKey);
    });
    if (notify) widget.onTimelineVisibilityChanged?.call(true);
  }

  void _backToBranches() {
    if (_submitting) return;
    setState(() {
      _branch = null;
      _selected.clear();
    });
    widget.onTimelineVisibilityChanged?.call(false);
  }

  void _refresh() {
    setState(() {
      _selected.clear();

      _scheduleFuture = _loadSchedule(_branch!.id, _dateKey);
    });
  }

  void _changeDate(DateTime date) {
    setState(() {
      _date = DateUtils.dateOnly(date);

      _selected.clear();
      _scheduleFuture = _loadSchedule(_branch!.id, _dateKey);
    });
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null && mounted) _changeDate(picked);
  }

  Map<String, List<String>> get _courtSlots {
    final groups = <String, List<String>>{};
    for (final selection in _selected.values) {
      groups
          .putIfAbsent(selection.court.id, () => [])
          .add(selection.slot.timeSlotId);
    }
    return groups;
  }

  void _toggle(Court court, BookingSlot slot) {
    final key = '${court.id}:${slot.timeSlotId}';
    setState(() {
      if (_selected.containsKey(key)) {
        _selected.remove(key);
      } else {
        _selected[key] = CourtSlotSelection(court: court, slot: slot);
      }
    });
  }

  Future<void> _review() async {
    if (_selected.isEmpty || _checkingLogin) return;
    setState(() => _checkingLogin = true);
    try {
      final token = await _tokenStorage.readToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        await _openLogin();
        return;
      }
    } finally {
      if (mounted) setState(() => _checkingLogin = false);
    }
    if (!mounted) return;
    final slots = _selected.values.toList()
      ..sort((a, b) {
        final courtOrder = a.court.name.compareTo(b.court.name);
        return courtOrder != 0
            ? courtOrder
            : a.slot.startTime.compareTo(b.slot.startTime);
      });
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xác nhận đặt sân',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                _branch!.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${_courtSlots.length} sân • $_dateLabel'),
              const SizedBox(height: 12),
              for (final slot in slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${slot.court.name}: ${slot.slot.startTime.substring(0, 5)} – ${slot.slot.endTime.substring(0, 5)}',
                        ),
                      ),
                      Text(_money(slot.slot.price)),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng tiền',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _money(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Thanh toán tại sân. Bạn cần đăng nhập tài khoản khách hàng để xác nhận.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xác nhận đặt sân'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _bookingApi.createBookings(
        bookingDate: _dateKey,
        courtSlots: _courtSlots,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đặt sân thành công.')));
      _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _tokenStorage.clearToken();
        if (mounted) await _openLogin();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.statusCode == 409
                ? 'Khung giờ vừa được đặt. Vui lòng chọn giờ khác.'
                : error.message,
          ),
        ),
      );
      if (error.statusCode == 409) _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đặt sân. Kiểm tra kết nối và thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountPage(
          authApi: widget.authApi,
          returnAfterAuthentication: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _branch == null ? _branchPicker() : _timelinePage();

  Widget _branchPicker() => Scaffold(
    appBar: AppBar(title: const Text('Đặt sân')),
    body: FutureBuilder<List<Branch>>(
      future: _branchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _error(
            'Không thể tải chi nhánh',
            () => setState(() => _branchesFuture = _branchApi.getBranches()),
          );
        }
        final branches = snapshot.data ?? [];
        if (branches.isEmpty) {
          return const Center(child: Text('Chưa có chi nhánh hoạt động.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Bạn muốn chơi ở đâu?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn chi nhánh để xem lịch trống và đặt sân.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final branch in branches)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('branch-${branch.id}'),
                    onTap: () => _chooseBranch(branch),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (branch.imageUrl?.isNotEmpty == true)
                          Image.network(
                            branch.imageUrl!,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                _branchPlaceholder(),
                          )
                        else
                          _branchPlaceholder(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(branch.address)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Giờ mở cửa: ${_shortTime(branch.openingTime)} – ${_shortTime(branch.closingTime)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Xem lịch & đặt sân',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  String _shortTime(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
  Widget _branchPlaceholder() => Container(
    height: 100,
    width: double.infinity,
    color: AppColors.primarySoft,
    child: const Icon(Icons.sports_tennis, size: 42, color: AppColors.primary),
  );

  Widget _timelinePage() => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _backToBranches();
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _submitting ? null : _backToBranches,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đặt lịch theo sân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _branch!.name,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _submitting ? null : _refresh,
            tooltip: 'Làm mới lịch',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chọn ngày đặt sân',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _submitting ? null : _pickDate,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .2),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(_dateLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    TimelineLegend(color: Colors.white, label: 'Trống'),
                    TimelineLegend(color: AppColors.info, label: 'Đã đặt'),
                    TimelineLegend(color: Color(0xFF9CA3AF), label: 'Khóa'),
                    TimelineLegend(
                      color: AppColors.primary,
                      label: 'Đang chọn',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.swipe_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mỗi ô 30 phút • Chạm ô trống để chọn',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CourtSchedule>>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDark,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _error('Không thể tải lịch sân', _refresh);
                }
                final schedules = snapshot.data ?? [];
                if (schedules.isEmpty) {
                  return _error(
                    'Chi nhánh này chưa có sân hoạt động.',
                    _refresh,
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      BookingTimeline(
                        schedules: schedules,
                        selectedCourtIds: _courtSlots.keys.toSet(),
                        selectedSlotKeys: _selected.keys.toSet(),
                        date: _date,
                        zoom: _zoom,
                        onSlotTap: _submitting ? null : _toggle,
                        onCourtInfo: (court) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CourtDetailPage(court: court),
                          ),
                        ),
                        onRetry: _submitting ? null : _refresh,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Chọn 1 ô để đặt 30 phút, 3 ô liền nhau để đặt 1 giờ 30 phút. Có thể chọn nhiều sân; chạm lại ô để bỏ chọn.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.zoom_out,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  Expanded(
                    child: Slider(
                      value: _zoom,
                      min: .65,
                      max: 1.8,
                      activeColor: AppColors.primaryDark,
                      onChanged: (value) => setState(() => _zoom = value),
                    ),
                  ),
                  const Icon(
                    Icons.zoom_in,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_courtSlots.length} sân • ${_selected.length} khung giờ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _money(_total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _selected.isEmpty || _submitting || _checkingLogin
                      ? null
                      : _review,
                  child: Text(_submitting ? 'Đang đặt sân...' : 'TIẾP THEO'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _error(String message, VoidCallback retry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
