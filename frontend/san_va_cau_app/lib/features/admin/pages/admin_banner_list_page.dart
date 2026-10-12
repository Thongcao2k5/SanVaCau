import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_content_api.dart';
import '../models/admin_content.dart';

class AdminBannerListPage extends StatefulWidget {
  const AdminBannerListPage({super.key, required this.role, this.api});

  final String role;
  final AdminContentApi? api;

  @override
  State<AdminBannerListPage> createState() => _AdminBannerListPageState();
}

class _AdminBannerListPageState extends State<AdminBannerListPage> {
  late final AdminContentApi _api;

  bool _isLoading = true;
  String? _error;
  List<AdminBanner> _banners = [];
  final Set<String> _mutatingIds = {};

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AdminContentApi();
    if (widget.role == 'ADMIN') {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final banners = await _api.getBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Không thể tải danh sách banner';
          _isLoading = false;
        });
      }
    }
  }

  void _showForm([AdminBanner? banner]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminBannerFormPage(api: _api, banner: banner),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _inactivate(AdminBanner banner) async {
    if (_mutatingIds.contains(banner.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy kích hoạt banner?'),
        content: const Text(
          'Banner sẽ ngừng hiển thị trên trang chủ. Nội dung đã lưu vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _mutatingIds.contains(banner.id)) {
      return;
    }
    setState(() => _mutatingIds.add(banner.id));
    try {
      await _api.inactivateBanner(banner.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy kích hoạt banner')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Không thể cập nhật banner',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _mutatingIds.remove(banner.id));
    }
  }

  void _showActionSheet(AdminBanner banner) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _showForm(banner);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AdminTheme.primary),
              title: const Text('Hủy kích hoạt'),
              onTap: () {
                Navigator.pop(context);
                _inactivate(banner);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role != 'ADMIN') {
      return Theme(
        data: AdminTheme.data(Theme.of(context)),
        child: Scaffold(
          appBar: AppBar(title: const Text('Quản lý banner')),
          body: SafeArea(
            child: const AdminStateView(
              icon: Icons.lock_rounded,
              title: 'Bạn không có quyền truy cập trang này.',
            ),
          ),
        ),
      );
    }

    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý banner'),
          backgroundColor: AdminTheme.graphite,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chỉ hiển thị banner đang hoạt động và trong thời gian hiệu lực.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AdminTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const AdminStateView(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Đang tải nội dung',
                        isLoading: true,
                      )
                    : _error != null
                    ? AdminStateView(
                        icon: Icons.cloud_off_rounded,
                        title: _error!,
                        actionLabel: 'Thử lại',
                        onAction: _loadData,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _banners.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  AdminStateView(
                                    icon: Icons.image_rounded,
                                    title: 'Không có banner nào đang hoạt động',
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  bottom: 80,
                                  left: 16,
                                  right: 16,
                                ),
                                itemCount: _banners.length,
                                itemBuilder: (context, index) {
                                  final banner = _banners[index];
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _BannerPreview(
                                          imageUrl: banner.imageUrl,
                                        ),
                                        ListTile(
                                          title: Text(
                                            banner.title.isNotEmpty
                                                ? banner.title
                                                : 'Banner không tiêu đề',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 6),
                                              Text(
                                                'Thứ tự: ${banner.sortOrder ?? 0}',
                                              ),
                                              const SizedBox(height: 8),
                                              AdminStatusBadge(
                                                label: banner.isActive
                                                    ? 'Đang hoạt động'
                                                    : 'Ngừng hiển thị',
                                                tone: banner.isActive
                                                    ? AdminStatusTone.success
                                                    : AdminStatusTone.neutral,
                                                icon: banner.isActive
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                              ),
                                            ],
                                          ),
                                          trailing:
                                              _mutatingIds.contains(banner.id)
                                              ? const SizedBox.square(
                                                  dimension: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : IconButton(
                                                  tooltip: 'Thao tác banner',
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                  ),
                                                  onPressed: () =>
                                                      _showActionSheet(banner),
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Thêm banner',
          onPressed: () => _showForm(),
          backgroundColor: AdminTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Xem trước banner',
    image: true,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: AdminTheme.canvas,
        child: imageUrl.isEmpty
            ? _placeholder('Chưa có ảnh banner')
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    _placeholder('Không thể tải ảnh banner'),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Đang tải ảnh banner',
                        ),
                      ),
              ),
      ),
    ),
  );
  Widget _placeholder(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.image_rounded,
          size: 32,
          color: AdminTheme.textSecondary,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _AdminBannerFormPage extends StatefulWidget {
  const _AdminBannerFormPage({required this.api, this.banner});

  final AdminContentApi api;
  final AdminBanner? banner;

  @override
  State<_AdminBannerFormPage> createState() => _AdminBannerFormPageState();
}

class _AdminBannerFormPageState extends State<_AdminBannerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _sortOrderController = TextEditingController();

  DateTime? _startAt;
  DateTime? _endAt;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      _titleController.text = widget.banner!.title;
      _imageUrlController.text = widget.banner!.imageUrl;
      _linkUrlController.text = widget.banner!.linkUrl ?? '';
      _sortOrderController.text = (widget.banner!.sortOrder ?? 0).toString();
      _startAt = widget.banner!.startAt;
      _endAt = widget.banner!.endAt;
    } else {
      _sortOrderController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isValidBannerSchedule(_startAt, _endAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian bắt đầu phải trước thời gian kết thúc'),
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

      if (widget.banner == null) {
        await widget.api.createBanner(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          linkUrl: _linkUrlController.text.trim().isEmpty
              ? null
              : _linkUrlController.text.trim(),
          sortOrder: sortOrder,
          startAt: _startAt,
          endAt: _endAt,
        );
      } else {
        await widget.api.updateBanner(
          id: widget.banner!.id,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          linkUrl: _linkUrlController.text.trim().isEmpty
              ? null
              : _linkUrlController.text.trim(),
          sortOrder: sortOrder,
          startAt: _startAt,
          endAt: _endAt,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lưu thành công')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Không thể lưu banner',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart
        ? (_startAt ?? DateTime.now())
        : (_endAt ?? DateTime.now().add(const Duration(days: 7)));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      setState(() {
        if (isStart) {
          _startAt = date;
        } else {
          _endAt = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.banner == null ? 'Thêm banner' : 'Chỉnh sửa banner',
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Lưu ý: Nếu bạn tạo banner có thời gian bắt đầu trong tương lai, banner sẽ không xuất hiện trong danh sách hiển thị hiện tại.',
                      style: TextStyle(
                        color: AdminTheme.warningText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: !_isSubmitting,
                      scrollPadding: const EdgeInsets.all(32),
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'URL Ảnh *'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _imageUrlController,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AdminTheme.compactRadius,
                        ),
                        child: _BannerPreview(imageUrl: value.text.trim()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: !_isSubmitting,
                      scrollPadding: const EdgeInsets.all(32),
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề (Tùy chọn)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: !_isSubmitting,
                      scrollPadding: const EdgeInsets.all(32),
                      controller: _linkUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Liên kết (Tùy chọn)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: !_isSubmitting,
                      scrollPadding: const EdgeInsets.all(32),
                      controller: _sortOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự sắp xếp',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v.trim()) == null) {
                          return 'Phải là số nguyên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thời gian bắt đầu:'),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today_rounded),
                                label: Text(
                                  _startAt != null
                                      ? _startAt!.toString().split(' ')[0]
                                      : 'Chọn ngày',
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _pickDate(true),
                              ),
                              if (_startAt != null)
                                TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => setState(() => _startAt = null),
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: AdminTheme.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thời gian kết thúc:'),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today_rounded),
                                label: Text(
                                  _endAt != null
                                      ? _endAt!.toString().split(' ')[0]
                                      : 'Chọn ngày',
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _pickDate(false),
                              ),
                              if (_endAt != null)
                                TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => setState(() => _endAt = null),
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: AdminTheme.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
