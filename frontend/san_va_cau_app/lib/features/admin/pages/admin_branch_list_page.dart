import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import 'package:image_picker/image_picker.dart';

import 'branch_image_crop_page.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/app_image.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/admin_court_api.dart';
import 'admin_court_list_page.dart';

class AdminBranchListPage extends StatefulWidget {
  const AdminBranchListPage({super.key, this.branchApi, this.courtApi});

  final BranchApi? branchApi;
  final AdminCourtApi? courtApi;

  @override
  State<AdminBranchListPage> createState() => _AdminBranchListPageState();
}

class _AdminBranchListPageState extends State<AdminBranchListPage> {
  late final BranchApi _branchApi = widget.branchApi ?? BranchApi();
  late Future<List<Branch>> _branches = _branchApi.getBranches();
  void _reload() {
    final future = _branchApi.getBranches();
    setState(() {
      _branches = future;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AdminTheme.data(Theme.of(context)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Quản lý chi nhánh')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => _BranchCreatePage(branchApi: _branchApi),
            ),
          );
          if (saved == true && mounted) _reload();
        },
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Thêm chi nhánh'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Branch>>(
          future: _branches,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminStateView(
                icon: Icons.storefront_rounded,
                title: 'Đang tải chi nhánh',
                isLoading: true,
              );
            }
            if (snapshot.hasError) {
              return AdminStateView(
                icon: Icons.cloud_off_rounded,
                title: 'Không thể tải chi nhánh. Thử lại',
                actionLabel: 'Thử lại',
                onAction: _reload,
              );
            }
            final branches = snapshot.data ?? [];
            if (branches.isEmpty) {
              return const AdminStateView(
                icon: Icons.storefront_rounded,
                title: 'Chưa có chi nhánh',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _branches;
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      button: true,
                      label: 'Thiết lập ${branch.name}',
                      child: AdminSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 7,
                              child: ColoredBox(
                                color: AdminTheme.softWine,
                                child: AppImage(
                                  source: branch.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  fallback: const Center(
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: AdminTheme.primary,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AdminTheme.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    branch.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AdminTheme.textSecondaryStrong,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 18,
                                        color: AdminTheme.textSecondaryStrong,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${branch.openingTime} – ${branch.closingTime}',
                                          style: const TextStyle(
                                            color:
                                                AdminTheme.textSecondaryStrong,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      AdminStatusBadge(
                                        label: branch.status == 'ACTIVE'
                                            ? 'Đang hoạt động'
                                            : 'Ngừng hoạt động',
                                        tone: branch.status == 'ACTIVE'
                                            ? AdminStatusTone.success
                                            : AdminStatusTone.neutral,
                                      ),
                                      if (branch.isFeatured)
                                        const AdminStatusBadge(
                                          label: 'Nổi bật trên Home',
                                          tone: AdminStatusTone.warning,
                                          icon: Icons.star_rounded,
                                        ),
                                    ],
                                  ),
                                  if (branch.isFeatured) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Thứ tự trên Home: ${branch.sortOrder}',
                                      style: const TextStyle(
                                        color: AdminTheme.textSecondaryStrong,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Thiết lập chi nhánh',
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
                            ),
                          ],
                        ),
                        onTap: () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => _BranchSettingsPage(
                                branch: branch,
                                branchApi: _branchApi,
                                courtApi: widget.courtApi,
                              ),
                            ),
                          );
                          if (saved == true && mounted) _reload();
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _BranchSettingsPage extends StatefulWidget {
  const _BranchSettingsPage({
    required this.branch,
    required this.branchApi,
    this.courtApi,
  });

  final Branch branch;
  final BranchApi branchApi;
  final AdminCourtApi? courtApi;

  @override
  State<_BranchSettingsPage> createState() => _BranchSettingsPageState();
}

class _BranchSettingsPageState extends State<_BranchSettingsPage> {
  XFile? _image;
  bool _saving = false;
  String? _error;
  late bool _isFeatured;
  late final TextEditingController _sortOrderController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _openingTimeController;
  late final TextEditingController _closingTimeController;

  @override
  void initState() {
    super.initState();
    _isFeatured = widget.branch.isFeatured;
    _sortOrderController = TextEditingController(
      text: widget.branch.sortOrder.toString(),
    );
    _nameController = TextEditingController(text: widget.branch.name);
    _addressController = TextEditingController(text: widget.branch.address);
    _phoneController = TextEditingController(text: widget.branch.phone ?? '');
    _descriptionController = TextEditingController(
      text: widget.branch.description ?? '',
    );
    _openingTimeController = TextEditingController(
      text: _normalizeBranchTimeForInput(widget.branch.openingTime),
    );
    _closingTimeController = TextEditingController(
      text: _normalizeBranchTimeForInput(widget.branch.closingTime),
    );
  }

  @override
  void dispose() {
    _sortOrderController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _crop() async {
    if (_image == null) return;
    final result = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => BranchImageCropPage(image: _image!)),
    );
    if (result != null && mounted) {
      setState(() {
        _image = result;
        _error = null;
      });
    }
  }

  Future<void> _pick() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _image = image;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể mở thư viện ảnh. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final openingTime = _openingTimeController.text.trim();
    final closingTime = _closingTimeController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      setState(() => _error = 'Tên và địa chỉ chi nhánh không được để trống.');
      return;
    }
    if (!_isValidTime(openingTime) || !_isValidTime(closingTime)) {
      setState(() => _error = 'Giờ hoạt động phải có định dạng HH:mm.');
      return;
    }
    if (_minutes(openingTime) >= _minutes(closingTime)) {
      setState(() => _error = 'Giờ mở cửa phải sớm hơn giờ đóng cửa.');
      return;
    }
    final sortOrder = int.tryParse(_sortOrderController.text.trim());
    if (sortOrder == null || sortOrder < 0) {
      setState(() => _error = 'Thứ tự phải là số nguyên không âm.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_image != null) {
        final token = await TokenStorage().readToken();
        if (token == null) {
          throw const ApiException(
            statusCode: 401,
            message: 'Vui lòng đăng nhập lại tài khoản admin',
          );
        }
        final upload = await ApiClient().postMultipart(
          '/uploads/image',
          filePath: _image!.path,
          token: token,
        );
        imageUrl =
            (upload['data'] as Map<String, dynamic>)['imageUrl'] as String;
      }
      await widget.branchApi.updateBranch(
        widget.branch.id,
        name: name,
        address: address,
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        openingTime: openingTime,
        closingTime: closingTime,
        imageUrl: imageUrl,
        isFeatured: _isFeatured,
        sortOrder: sortOrder,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu chi nhánh')));
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể lưu ảnh. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _inactivate() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngừng hoạt động chi nhánh?'),
        content: const Text(
          'Chi nhánh sẽ không còn hiển thị cho người dùng. Các dữ liệu sân và lịch sử vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ngừng hoạt động'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.branchApi.inactivateBranch(widget.branch.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ngừng hoạt động chi nhánh')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể ngừng hoạt động chi nhánh. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AdminTheme.data(Theme.of(context)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Thiết lập chi nhánh')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'Các trường có dấu * là bắt buộc.',
              style: TextStyle(color: AdminTheme.textSecondaryStrong),
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Thông tin chi nhánh',
              icon: Icons.storefront_rounded,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Tên chi nhánh *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Địa chỉ *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Giờ hoạt động',
              icon: Icons.schedule_rounded,
              children: [
                _BranchHours(
                  opening: _openingTimeController,
                  closing: _closingTimeController,
                  enabled: !_saving,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Hình ảnh chi nhánh',
              icon: Icons.image_rounded,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
                  child: ColoredBox(
                    color: AdminTheme.softWine,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _image == null
                          ? AppImage(
                              source: widget.branch.imageUrl ?? '',
                              fit: BoxFit.cover,
                              fallback: const Center(
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: AdminTheme.primary,
                                  size: 48,
                                ),
                              ),
                            )
                          : Image.file(File(_image!.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pick,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Chọn ảnh'),
                ),
                if (_image != null)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _crop,
                    icon: const Icon(Icons.crop_rounded),
                    label: const Text('Cắt ảnh theo khung 16:9'),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Ảnh JPEG, PNG hoặc WebP, tối đa 5 MB.',
                  style: TextStyle(color: AdminTheme.textSecondaryStrong),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Hiển thị trên trang chủ',
              icon: Icons.star_rounded,
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: AdminTheme.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chi nhánh nổi bật'),
                  subtitle: const Text(
                    'Hiển thị trong khu vực nổi bật ở trang chủ',
                  ),
                  value: _isFeatured,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isFeatured = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sortOrderController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thứ tự hiển thị',
                    prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    helperText: 'Trên Home, số nhỏ hơn sẽ xuất hiện trước',
                    helperMaxLines: 3,
                  ),
                ),
              ],
            ),
            if (_error != null) _BranchError(message: _error!),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('branch-settings-save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
            const SizedBox(height: 24),
            _BranchSection(
              title: 'Vận hành chi nhánh',
              icon: Icons.sports_tennis_rounded,
              children: [
                const Text(
                  'Quản lý sân, khung giờ và giá đặt sân tại chi nhánh.',
                  style: TextStyle(color: AdminTheme.textSecondaryStrong),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminCourtListPage(
                              branch: widget.branch,
                              courtApi: widget.courtApi,
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.sports_tennis_rounded),
                  label: const Text('Quản lý sân và bảng giá'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _BranchSection(
              title: 'Ngừng hoạt động',
              icon: Icons.block_rounded,
              children: [
                const Text(
                  'Chi nhánh sẽ được ẩn khỏi giao diện người dùng. Dữ liệu sân và lịch sử vẫn được giữ lại.',
                  style: TextStyle(color: AdminTheme.textSecondaryStrong),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _inactivate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.primary,
                    side: const BorderSide(color: AdminTheme.primary),
                  ),
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Ngừng hoạt động chi nhánh'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _BranchCreatePage extends StatefulWidget {
  const _BranchCreatePage({required this.branchApi});

  final BranchApi branchApi;

  @override
  State<_BranchCreatePage> createState() => _BranchCreatePageState();
}

class _BranchCreatePageState extends State<_BranchCreatePage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingTimeController = TextEditingController(text: '06:00');
  final _closingTimeController = TextEditingController(text: '22:00');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final openingTime = _openingTimeController.text.trim();
    final closingTime = _closingTimeController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên và địa chỉ chi nhánh.');
      return;
    }
    if (!_isValidTime(openingTime) || !_isValidTime(closingTime)) {
      setState(() => _error = 'Giờ hoạt động phải có định dạng HH:mm.');
      return;
    }
    if (_minutes(openingTime) >= _minutes(closingTime)) {
      setState(() => _error = 'Giờ mở cửa phải sớm hơn giờ đóng cửa.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.branchApi.createBranch(
        name: name,
        address: address,
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        openingTime: openingTime,
        closingTime: closingTime,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tạo chi nhánh. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AdminTheme.data(Theme.of(context)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Thêm chi nhánh')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'Các trường có dấu * là bắt buộc.',
              style: TextStyle(color: AdminTheme.textSecondaryStrong),
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Thông tin chính',
              icon: Icons.storefront_rounded,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Tên chi nhánh *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  enabled: !_saving,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Địa chỉ *'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Liên hệ & mô tả',
              icon: Icons.contact_phone_rounded,
              children: [
                const Text(
                  'Thông tin bổ sung · không bắt buộc',
                  style: TextStyle(color: AdminTheme.textSecondaryStrong),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BranchSection(
              title: 'Giờ hoạt động',
              icon: Icons.schedule_rounded,
              children: [
                _BranchHours(
                  opening: _openingTimeController,
                  closing: _closingTimeController,
                  enabled: !_saving,
                ),
              ],
            ),
            if (_error != null) _BranchError(message: _error!),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('branch-create-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.add_business_rounded),
              label: Text(_saving ? 'Đang tạo...' : 'Tạo chi nhánh'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BranchSection extends StatelessWidget {
  const _BranchSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AdminIconBox(icon: icon, color: AdminTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );
}

class _BranchHours extends StatelessWidget {
  const _BranchHours({
    required this.opening,
    required this.closing,
    required this.enabled,
  });

  final TextEditingController opening;
  final TextEditingController closing;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final fields = [
        TextField(
          key: const Key('branch-opening-time'),
          controller: opening,
          enabled: enabled,
          decoration: const InputDecoration(labelText: 'Mở cửa (HH:mm) *'),
        ),
        TextField(
          key: const Key('branch-closing-time'),
          controller: closing,
          enabled: enabled,
          decoration: const InputDecoration(labelText: 'Đóng cửa (HH:mm) *'),
        ),
      ];
      if (constraints.maxWidth < 400 ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.3) {
        return Column(
          children: [fields[0], const SizedBox(height: 16), fields[1]],
        );
      }
      return Row(
        children: [
          Expanded(child: fields[0]),
          const SizedBox(width: 12),
          Expanded(child: fields[1]),
        ],
      );
    },
  );
}

class _BranchError extends StatelessWidget {
  const _BranchError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AdminSurface(
        color: AdminTheme.softWine,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_rounded, color: AdminTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AdminTheme.primaryText),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _normalizeBranchTimeForInput(String value) =>
    RegExp(r'^((?:[01]\d|2[0-3]):[0-5]\d):00$').firstMatch(value)?.group(1) ??
    value;

bool _isValidTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return false;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
}

int _minutes(String value) {
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
