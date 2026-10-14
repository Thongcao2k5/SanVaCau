import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/network/api_client.dart';
import '../../booking/models/court.dart';
import '../../branches/models/branch.dart';
import '../data/admin_court_api.dart';
import '../models/admin_court.dart';

class AdminCourtListPage extends StatefulWidget {
  const AdminCourtListPage({super.key, required this.branch, this.courtApi});

  final Branch branch;
  final AdminCourtApi? courtApi;

  @override
  State<AdminCourtListPage> createState() => _AdminCourtListPageState();
}

class _AdminCourtListPageState extends State<AdminCourtListPage> {
  late final AdminCourtApi _api;
  late Future<List<Court>> _courtsFuture;

  @override
  void initState() {
    super.initState();
    _api = widget.courtApi ?? AdminCourtApi();
    _reload();
  }

  void _reload() {
    final future = _api.getCourts(widget.branch.id);
    setState(() {
      _courtsFuture = future;
    });
  }

  Future<void> _openForm([Court? court]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            _CourtFormPage(branch: widget.branch, court: court, api: _api),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _inactivate(Court court) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngừng hoạt động sân?'),
        content: Text(
          '${court.name} sẽ không còn xuất hiện trong luồng đặt sân. '
          'Các lịch đã tạo vẫn được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ngừng hoạt động'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.inactivateCourt(court.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã ngừng hoạt động sân')));
        _reload();
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sân • ${widget.branch.name}'),
          actions: [
            IconButton(
              tooltip: 'Quản lý khung giờ',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AdminTimeSlotPage(courtApi: _api),
                ),
              ),
              icon: const Icon(Icons.schedule_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<Court>>(
            future: _courtsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminStateView(
                  icon: Icons.sports_tennis_rounded,
                  title: 'Đang tải danh sách sân',
                  isLoading: true,
                );
              }
              if (snapshot.hasError) {
                return _AdminCourtState(
                  icon: Icons.cloud_off_rounded,
                  message: 'Không thể tải danh sách sân',
                  actionLabel: 'Thử lại',
                  onAction: _reload,
                );
              }
              final courts = snapshot.data ?? const <Court>[];
              if (courts.isEmpty) {
                return _AdminCourtState(
                  icon: Icons.sports_tennis_rounded,
                  message: 'Chi nhánh chưa có sân hoạt động',
                  actionLabel: 'Thêm sân đầu tiên',
                  onAction: _openForm,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _courtsFuture;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                  itemCount: courts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    return AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AdminIconBox(
                                icon: Icons.sports_tennis_rounded,
                                color: AdminTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  court.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.textPrimary,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Thao tác sân',
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: AdminTheme.textSecondaryStrong,
                                ),
                                onSelected: (action) {
                                  if (action == 'edit') _openForm(court);
                                  if (action == 'price') {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _CourtPricePage(
                                          court: court,
                                          api: _api,
                                        ),
                                      ),
                                    );
                                  }
                                  if (action == 'inactivate') {
                                    _inactivate(court);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.edit_rounded),
                                      title: Text('Sửa sân'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'price',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.payments_rounded),
                                      title: Text('Bảng giá'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'inactivate',
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.block_rounded,
                                        color: AdminTheme.primary,
                                      ),
                                      title: Text(
                                        'Ngừng hoạt động',
                                        style: TextStyle(
                                          color: AdminTheme.primaryText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            court.description?.trim().isNotEmpty == true
                                ? court.description!
                                : 'Chưa có mô tả',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminTheme.textSecondaryStrong,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AdminStatusBadge(
                            label: switch (court.status) {
                              'ACTIVE' => 'Đang hoạt động',
                              'INACTIVE' => 'Ngừng hoạt động',
                              'MAINTENANCE' => 'Bảo trì',
                              _ => court.status,
                            },
                            tone: court.status == 'ACTIVE'
                                ? AdminStatusTone.success
                                : AdminStatusTone.neutral,
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Xem bảng giá',
                                  style: TextStyle(
                                    color: AdminTheme.primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: AdminTheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _CourtPricePage(court: court, api: _api),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AdminTheme.primary,
          foregroundColor: Colors.white,
          onPressed: _openForm,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm sân'),
        ),
      ),
    );
  }
}

class _CourtFormPage extends StatefulWidget {
  const _CourtFormPage({required this.branch, required this.api, this.court});

  final Branch branch;
  final Court? court;
  final AdminCourtApi api;

  @override
  State<_CourtFormPage> createState() => _CourtFormPageState();
}

class _CourtFormPageState extends State<_CourtFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.court?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.court?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final description = _descriptionController.text.trim();
      if (widget.court == null) {
        await widget.api.createCourt(
          branchId: widget.branch.id,
          name: _nameController.text.trim(),
          description: description.isEmpty ? null : description,
        );
      } else {
        await widget.api.updateCourt(
          id: widget.court!.id,
          name: _nameController.text.trim(),
          description: description.isEmpty ? null : description,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể lưu sân.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.court == null ? 'Thêm sân' : 'Sửa sân'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              children: [
                AdminSurface(
                  color: AdminTheme.softWine,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AdminTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.branch.name,
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Thông tin sân',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tên sân là bắt buộc. Mô tả không bắt buộc.',
                        style: TextStyle(color: AdminTheme.textSecondaryStrong),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('court-name'),
                        enabled: !_saving,
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên sân',
                          prefixIcon: Icon(Icons.sports_tennis_rounded),
                          errorMaxLines: 3,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Nhập tên sân'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('court-description'),
                        enabled: !_saving,
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          alignLabelWithHint: true,
                        ),
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: AdminSurface(
                      color: AdminTheme.softWine,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_rounded,
                            color: AdminTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AdminTheme.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('court-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu...' : 'Lưu sân'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourtPricePage extends StatefulWidget {
  const _CourtPricePage({required this.court, required this.api});

  final Court court;
  final AdminCourtApi api;

  @override
  State<_CourtPricePage> createState() => _CourtPricePageState();
}

class _CourtPricePageState extends State<_CourtPricePage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<AdminTimeSlot> _slots = const [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getTimeSlots(),
        widget.api.getCourtPrices(widget.court.id),
      ]);
      if (!mounted) return;
      final slots = results[0] as List<AdminTimeSlot>;
      final prices = results[1] as List<CourtPrice>;
      final priceBySlot = {
        for (final price in prices) price.timeSlotId: price.price,
      };
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      for (final slot in slots) {
        final price = priceBySlot[slot.id];
        _controllers[slot.id] = TextEditingController(
          text: price == null
              ? ''
              : price.isFinite && price == price.truncateToDouble()
              ? price.toStringAsFixed(0)
              : price.toString(),
        );
      }
      if (mounted) setState(() => _slots = slots);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tải bảng giá.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final prices = <String, double>{};
    for (final slot in _slots) {
      final value = double.tryParse(_controllers[slot.id]!.text.trim());
      if (value == null || !value.isFinite || value <= 0) {
        setState(() => _error = 'Nhập giá hợp lệ cho tất cả khung giờ.');
        return;
      }
      prices[slot.id] = value;
    }
    if (prices.isEmpty) {
      setState(() => _error = 'Hãy tạo khung giờ trước khi cập nhật giá.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateCourtPrices(
        courtId: widget.court.id,
        prices: prices,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật bảng giá')));
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể lưu bảng giá. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(title: Text('Bảng giá • ${widget.court.name}')),
        body: SafeArea(
          child: _loading
              ? const AdminStateView(
                  icon: Icons.payments_rounded,
                  title: 'Đang tải bảng giá',
                  isLoading: true,
                )
              : _error != null && _slots.isEmpty
              ? _AdminCourtState(
                  icon: Icons.error_outline_rounded,
                  message: _error!,
                  actionLabel: 'Thử lại',
                  onAction: _load,
                )
              : _slots.isEmpty
              ? AdminStateView(
                  icon: Icons.schedule_rounded,
                  title: 'Chưa có khung giờ',
                  message: 'Hãy tạo khung giờ trước khi cập nhật giá.',
                  actionLabel: 'Thử lại',
                  onAction: _load,
                )
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    AdminSurface(
                      color: AdminTheme.softWine,
                      child: Row(
                        children: [
                          const AdminIconBox(
                            icon: Icons.sports_tennis_rounded,
                            color: AdminTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đang thiết lập giá cho',
                                  style: TextStyle(
                                    color: AdminTheme.textSecondaryStrong,
                                  ),
                                ),
                                Text(
                                  widget.court.name,
                                  style: const TextStyle(
                                    color: AdminTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Giá theo khung giờ',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nhập giá lớn hơn 0 cho từng khung giờ. Đơn vị: đồng (đ).',
                      style: TextStyle(color: AdminTheme.textSecondaryStrong),
                    ),
                    const SizedBox(height: 20),
                    for (final slot in _slots) ...[
                      AdminSurface(
                        child: TextFormField(
                          key: ValueKey('court-price-${slot.id}'),
                          enabled: !_saving,
                          controller: _controllers[slot.id],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${_shortTime(slot.startTime)} – ${_shortTime(slot.endTime)}',
                            suffixText: 'đ',
                            hintText: 'Chưa có giá',
                            prefixIcon: const Icon(
                              Icons.payments_rounded,
                              color: AdminTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Semantics(
                        liveRegion: true,
                        child: AdminSurface(
                          color: AdminTheme.softWine,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_rounded,
                                color: AdminTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AdminTheme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('court-price-save'),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Đang lưu...' : 'Lưu bảng giá'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AdminTimeSlotPage extends StatefulWidget {
  const AdminTimeSlotPage({super.key, this.courtApi});

  final AdminCourtApi? courtApi;

  @override
  State<AdminTimeSlotPage> createState() => _AdminTimeSlotPageState();
}

class _AdminTimeSlotPageState extends State<AdminTimeSlotPage> {
  late final AdminCourtApi _api;
  late Future<List<AdminTimeSlot>> _future;

  @override
  void initState() {
    super.initState();
    _api = widget.courtApi ?? AdminCourtApi();
    _reload();
  }

  void _reload() {
    final future = _api.getTimeSlots();
    setState(() {
      _future = future;
    });
  }

  Future<void> _openForm([AdminTimeSlot? slot]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TimeSlotDialog(api: _api, slot: slot),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _inactivate(AdminTimeSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tắt khung giờ?'),
        content: const Text(
          'Khung giờ sẽ không còn xuất hiện trong bảng giá và lịch đặt mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tắt khung giờ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.updateTimeSlot(
        id: slot.id,
        startTime: slot.startTime,
        endTime: slot.endTime,
        sortOrder: slot.sortOrder,
        isActive: false,
      );
      if (mounted) _reload();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Khung giờ đặt sân')),
        body: SafeArea(
          child: FutureBuilder<List<AdminTimeSlot>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminStateView(
                  icon: Icons.schedule_rounded,
                  title: 'Đang tải khung giờ',
                  isLoading: true,
                );
              }
              if (snapshot.hasError) {
                return _AdminCourtState(
                  icon: Icons.cloud_off_rounded,
                  message: 'Không thể tải khung giờ',
                  actionLabel: 'Thử lại',
                  onAction: _reload,
                );
              }
              final slots = snapshot.data ?? const <AdminTimeSlot>[];
              if (slots.isEmpty) {
                return _AdminCourtState(
                  icon: Icons.schedule_rounded,
                  message: 'Chưa có khung giờ hoạt động',
                  actionLabel: 'Thêm khung giờ',
                  onAction: _openForm,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                itemCount: slots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  return AdminSurface(
                    onTap: () => _openForm(slot),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AdminIconBox(
                              icon: Icons.schedule_rounded,
                              color: AdminTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_shortTime(slot.startTime)} – ${_shortTime(slot.endTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AdminTheme.textPrimary,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Thao tác khung giờ',
                              onSelected: (action) {
                                if (action == 'edit') _openForm(slot);
                                if (action == 'disable') _inactivate(slot);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.edit_rounded),
                                    title: Text('Chỉnh sửa'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'disable',
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.block_rounded,
                                      color: AdminTheme.primary,
                                    ),
                                    title: Text(
                                      'Tắt',
                                      style: TextStyle(
                                        color: AdminTheme.primaryText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AdminStatusBadge(
                              label: slot.isActive
                                  ? 'Đang hoạt động'
                                  : 'Đã tắt',
                              tone: slot.isActive
                                  ? AdminStatusTone.success
                                  : AdminStatusTone.neutral,
                            ),
                            Text(
                              'Thứ tự ${slot.sortOrder}',
                              style: const TextStyle(
                                color: AdminTheme.textSecondaryStrong,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Chỉnh sửa khung giờ',
                                style: TextStyle(
                                  color: AdminTheme.primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AdminTheme.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm khung giờ'),
          backgroundColor: AdminTheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _TimeSlotDialog extends StatefulWidget {
  const _TimeSlotDialog({required this.api, this.slot});

  final AdminCourtApi api;
  final AdminTimeSlot? slot;

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _orderController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(
      text: _shortTime(widget.slot?.startTime ?? ''),
    );
    _endController = TextEditingController(
      text: _shortTime(widget.slot?.endTime ?? ''),
    );
    _orderController = TextEditingController(
      text: widget.slot?.sortOrder.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final start = _startController.text.trim();
    final end = _endController.text.trim();
    final order = int.tryParse(_orderController.text.trim());
    final validTime = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (!validTime.hasMatch(start) ||
        !validTime.hasMatch(end) ||
        start.compareTo(end) >= 0) {
      setState(() => _error = 'Giờ bắt đầu/kết thúc không hợp lệ.');
      return;
    }
    if (order == null || order < 0) {
      setState(() => _error = 'Thứ tự phải là số nguyên không âm.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.slot == null) {
        await widget.api.createTimeSlot(
          startTime: start,
          endTime: end,
          sortOrder: order,
        );
      } else {
        await widget.api.updateTimeSlot(
          id: widget.slot!.id,
          startTime: start,
          endTime: end,
          sortOrder: order,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: AlertDialog(
        backgroundColor: AdminTheme.surface,
        surfaceTintColor: Colors.transparent,
        scrollable: true,
        title: Text(widget.slot == null ? 'Thêm khung giờ' : 'Sửa khung giờ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Khung giờ dùng chung cho lịch đặt sân. Nhập giờ theo định dạng HH:mm.',
              style: TextStyle(color: AdminTheme.textSecondaryStrong),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('slot-start'),
              enabled: !_saving,
              controller: _startController,
              decoration: const InputDecoration(labelText: 'Bắt đầu (HH:mm)'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('slot-end'),
              enabled: !_saving,
              controller: _endController,
              decoration: const InputDecoration(labelText: 'Kết thúc (HH:mm)'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('slot-order'),
              enabled: !_saving,
              controller: _orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thứ tự',
                helperText: 'Số nguyên từ 0; số nhỏ hơn xếp trước.',
                helperMaxLines: 3,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: AdminSurface(
                  color: AdminTheme.softWine,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_rounded,
                        color: AdminTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AdminTheme.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            key: const Key('slot-save'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      ),
    );
  }
}

class _AdminCourtState extends StatelessWidget {
  const _AdminCourtState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AdminStateView(
      icon: icon,
      title: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;
