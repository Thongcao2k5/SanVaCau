import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
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
    return Scaffold(
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
      body: FutureBuilder<List<Court>>(
        future: _courtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: courts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final court = courts[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports_tennis_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      court.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      court.description?.trim().isNotEmpty == true
                          ? court.description!
                          : 'Chưa có mô tả',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') _openForm(court);
                        if (action == 'price') {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  _CourtPricePage(court: court, api: _api),
                            ),
                          );
                        }
                        if (action == 'inactivate') _inactivate(court);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Sửa sân')),
                        PopupMenuItem(value: 'price', child: Text('Bảng giá')),
                        PopupMenuItem(
                          value: 'inactivate',
                          child: Text('Ngừng hoạt động'),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _CourtPricePage(court: court, api: _api),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sân'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.court == null ? 'Thêm sân' : 'Sửa sân'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.branch.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên sân',
                prefixIcon: Icon(Icons.sports_tennis_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Nhập tên sân' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 5,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.primary)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu sân'),
            ),
          ],
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
          text: price == null ? '' : price.round().toString(),
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
      if (value == null || value <= 0) {
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bảng giá • ${widget.court.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _slots.isEmpty
          ? _AdminCourtState(
              icon: Icons.error_outline_rounded,
              message: _error!,
              actionLabel: 'Thử lại',
              onAction: _load,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Giá theo khung giờ',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Giá phải lớn hơn 0 và áp dụng cho một lượt đặt sân.',
                ),
                const SizedBox(height: 20),
                for (final slot in _slots) ...[
                  TextFormField(
                    controller: _controllers[slot.id],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          '${_shortTime(slot.startTime)} – ${_shortTime(slot.endTime)}',
                      suffixText: 'đ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu...' : 'Lưu bảng giá'),
                ),
              ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Khung giờ đặt sân')),
      body: FutureBuilder<List<AdminTimeSlot>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: slots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final slot = slots[index];
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    '${_shortTime(slot.startTime)} – ${_shortTime(slot.endTime)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('Thứ tự ${slot.sortOrder}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _openForm(slot);
                      if (action == 'disable') _inactivate(slot);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                      PopupMenuItem(value: 'disable', child: Text('Tắt')),
                    ],
                  ),
                  onTap: () => _openForm(slot),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm khung giờ'),
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
    return AlertDialog(
      title: Text(widget.slot == null ? 'Thêm khung giờ' : 'Sửa khung giờ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _startController,
              decoration: const InputDecoration(labelText: 'Bắt đầu (HH:mm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endController,
              decoration: const InputDecoration(labelText: 'Kết thúc (HH:mm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thứ tự'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.primary)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Bỏ qua'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;
