import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/admin_content_api.dart';
import '../models/admin_content.dart';

class AdminNewsListPage extends StatefulWidget {
  const AdminNewsListPage({
    super.key,
    required this.role,
    this.api,
    this.branchApi,
  });

  final String role;
  final AdminContentApi? api;
  final BranchApi? branchApi;

  @override
  State<AdminNewsListPage> createState() => _AdminNewsListPageState();
}

class _AdminNewsListPageState extends State<AdminNewsListPage> {
  late final AdminContentApi _api;

  bool _isLoading = true;
  String? _error;
  List<AdminNewsArticle> _news = [];
  String _statusFilter = 'PUBLISHED';
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
      final news = await _api.getNews(status: _statusFilter, limit: 50);
      if (mounted) {
        setState(() {
          _news = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Không thể tải danh sách tin tức';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeStatus(String status) async {
    setState(() {
      _statusFilter = status;
    });
    await _loadData();
  }

  void _showForm([AdminNewsArticle? article]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminNewsFormPage(
          api: _api,
          branchApi: widget.branchApi ?? BranchApi(),
          article: article,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _mutateStatus(
    AdminNewsArticle article,
    Future<AdminNewsArticle> Function() request,
    String successMessage,
  ) async {
    if (_mutatingIds.contains(article.id)) return;

    setState(() => _mutatingIds.add(article.id));
    try {
      await request();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Không thể cập nhật tin tức',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _mutatingIds.remove(article.id));
    }
  }

  void _showActionSheet(AdminNewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.surface,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: AdminTheme.primary,
                ),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  _showForm(article);
                },
              ),
              if (article.status != 'PUBLISHED')
                ListTile(
                  leading: const Icon(
                    Icons.public_rounded,
                    color: AppColors.success,
                  ),
                  title: const Text('Xuất bản'),
                  onTap: () {
                    Navigator.pop(context);
                    _mutateStatus(
                      article,
                      () => _api.publishNews(article.id),
                      'Xuất bản thành công',
                    );
                  },
                ),
              if (article.status != 'ARCHIVED')
                ListTile(
                  leading: const Icon(
                    Icons.archive_rounded,
                    color: AdminTheme.warningText,
                  ),
                  title: const Text('Lưu trữ'),
                  onTap: () {
                    Navigator.pop(context);
                    _mutateStatus(
                      article,
                      () => _api.archiveNews(article.id),
                      'Đã lưu trữ thành công',
                    );
                  },
                ),
            ],
          ),
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
          appBar: AppBar(title: const Text('Quản lý tin tức')),
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
        appBar: AppBar(title: const Text('Quản lý tin tức')),
        body: SafeArea(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip('Đã xuất bản', 'PUBLISHED'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Bản nháp', 'DRAFT'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Lưu trữ', 'ARCHIVED'),
                  ],
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
                        child: _news.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  AdminStateView(
                                    icon: Icons.article_rounded,
                                    title: 'Không có tin tức nào',
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  bottom: 96,
                                  left: 20,
                                  right: 20,
                                ),
                                itemCount: _news.length,
                                itemBuilder: (context, index) {
                                  final article = _news[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AdminSurface(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 160,
                                            width: double.infinity,
                                            child: ColoredBox(
                                              color: AdminTheme.softWine,
                                              child: AppImage(
                                                source: article.thumbnailUrl,
                                                fit: BoxFit.cover,
                                                fallback: const Center(
                                                  child: Icon(
                                                    Icons.newspaper_rounded,
                                                    size: 40,
                                                    color: AdminTheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(16),
                                            title: Text(
                                              article.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text(
                                                  article.summary,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                AdminStatusBadge(
                                                  label:
                                                      switch (article.status) {
                                                        'DRAFT' => 'Bản nháp',
                                                        'PUBLISHED' =>
                                                          'Đã xuất bản',
                                                        'ARCHIVED' => 'Lưu trữ',
                                                        _ => article.status,
                                                      },
                                                  tone: switch (article
                                                      .status) {
                                                    'PUBLISHED' =>
                                                      AdminStatusTone.success,
                                                    'DRAFT' =>
                                                      AdminStatusTone.warning,
                                                    _ =>
                                                      AdminStatusTone.neutral,
                                                  },
                                                  icon: switch (article
                                                      .status) {
                                                    'DRAFT' =>
                                                      Icons.edit_note_rounded,
                                                    'PUBLISHED' =>
                                                      Icons.public_rounded,
                                                    _ => Icons.archive_rounded,
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tác giả: ${article.authorName}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AdminTheme
                                                        .textSecondaryStrong,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing:
                                                _mutatingIds.contains(
                                                  article.id,
                                                )
                                                ? const SizedBox.square(
                                                    dimension: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : IconButton(
                                                    tooltip: 'Thao tác tin tức',
                                                    icon: const Icon(
                                                      Icons.more_vert,
                                                    ),
                                                    onPressed: () =>
                                                        _showActionSheet(
                                                          article,
                                                        ),
                                                  ),
                                          ),
                                        ],
                                      ),
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
          tooltip: 'Tạo tin tức',
          onPressed: () => _showForm(),
          backgroundColor: AdminTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (selected) {
        if (selected) _changeStatus(value);
      },
    );
  }
}

class _AdminNewsFormPage extends StatefulWidget {
  const _AdminNewsFormPage({
    required this.api,
    required this.branchApi,
    this.article,
  });

  final AdminContentApi api;
  final BranchApi branchApi;
  final AdminNewsArticle? article;

  @override
  State<_AdminNewsFormPage> createState() => _AdminNewsFormPageState();
}

class _AdminNewsFormPageState extends State<_AdminNewsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _thumbnailController = TextEditingController();

  bool _isSubmitting = false;
  String? _saveError;
  String? _branchId;

  List<Branch> _branches = [];
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _summaryController.text = widget.article!.summary;
      _contentController.text = widget.article!.content;
      _thumbnailController.text = widget.article!.thumbnailUrl;
      _branchId = widget.article!.branch?.id;
    }
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await widget.branchApi.getBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _isLoadingBranches = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBranches = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _saveError = null;
    });

    try {
      if (widget.article == null) {
        await widget.api.createNews(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          summary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          thumbnailUrl: _thumbnailController.text.trim().isEmpty
              ? null
              : _thumbnailController.text.trim(),
          branchId: _branchId,
        );
      } else {
        await widget.api.updateNews(
          id: widget.article!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          summary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          thumbnailUrl: _thumbnailController.text.trim().isEmpty
              ? null
              : _thumbnailController.text.trim(),
          branchId: _branchId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Thành công')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _saveError = e is ApiException ? e.message : 'Không thể lưu tin tức';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Không thể lưu tin tức',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.article == null ? 'Tạo tin tức' : 'Chỉnh sửa tin tức',
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Các trường có dấu * là bắt buộc.',
                      style: TextStyle(color: AdminTheme.textSecondaryStrong),
                    ),
                    const SizedBox(height: 16),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Nội dung bài viết',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('news-title'),
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Tiêu đề *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Không được để trống'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('news-summary'),
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _summaryController,
                            decoration: const InputDecoration(
                              labelText: 'Tóm tắt (Tùy chọn)',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('news-content'),
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'Nội dung *',
                            ),
                            minLines: 4,
                            maxLines: 10,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Không được để trống'
                                : null,
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
                            'Ảnh bìa & chi nhánh',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('news-thumbnail'),
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _thumbnailController,
                            decoration: const InputDecoration(
                              labelText: 'URL Ảnh bìa (Tùy chọn)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isLoadingBranches)
                            DropdownButtonFormField<String?>(
                              key: const Key('news-branch'),
                              isExpanded: true,
                              initialValue: _branchId,
                              decoration: const InputDecoration(
                                labelText: 'Chi nhánh (Tùy chọn)',
                                helperText:
                                    'Để trống để áp dụng toàn hệ thống.',
                                helperMaxLines: 3,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Toàn hệ thống'),
                                ),
                                ..._branches.map(
                                  (b) => DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name),
                                  ),
                                ),
                                if (_branchId != null &&
                                    !_branches.any((b) => b.id == _branchId))
                                  DropdownMenuItem(
                                    value: _branchId,
                                    child: Text(
                                      '${widget.article?.branch?.name ?? _branchId} (không có trong danh sách)',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _isSubmitting
                                  ? null
                                  : (v) => setState(() => _branchId = v),
                            ),
                        ],
                      ),
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: AdminSurface(
                          color: AdminTheme.softWine,
                          child: Text(
                            _saveError!,
                            style: const TextStyle(
                              color: AdminTheme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('news-save'),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const Text('Đang lưu...')
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
