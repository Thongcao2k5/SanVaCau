import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'branch_image_crop_page.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/app_image.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';

class AdminBranchListPage extends StatefulWidget {
  const AdminBranchListPage({super.key});
  @override
  State<AdminBranchListPage> createState() => _AdminBranchListPageState();
}

class _AdminBranchListPageState extends State<AdminBranchListPage> {
  late Future<List<Branch>> _branches = BranchApi().getBranches();
  void _reload() => setState(() => _branches = BranchApi().getBranches());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quản lý chi nhánh')),
    body: FutureBuilder<List<Branch>>(
      future: _branches,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text('Không thể tải chi nhánh. Thử lại'),
            ),
          );
        }
        final branches = snapshot.data ?? [];
        if (branches.isEmpty) {
          return const Center(child: Text('Chưa có chi nhánh'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _branches;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branch = branches[index];
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 64,
                    height: 64,
                    child: AppImage(
                      source: branch.imageUrl ?? '',
                      fallback: const Icon(Icons.store_outlined),
                    ),
                  ),
                  title: Text(branch.name),
                  subtitle: Text(branch.address),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => _BranchImagePage(branch: branch),
                      ),
                    );
                    if (saved == true && mounted) _reload();
                  },
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _BranchImagePage extends StatefulWidget {
  const _BranchImagePage({required this.branch});
  final Branch branch;
  @override
  State<_BranchImagePage> createState() => _BranchImagePageState();
}

class _BranchImagePageState extends State<_BranchImagePage> {
  XFile? _image;
  bool _saving = false;
  String? _error;
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
    if (_image == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await TokenStorage().readToken();
      if (token == null) {
        throw const ApiException(
          statusCode: 401,
          message: 'Vui lòng đăng nhập lại tài khoản admin',
        );
      }
      final client = ApiClient();
      final upload = await client.postMultipart(
        '/uploads/image',
        filePath: _image!.path,
        token: token,
      );
      final url =
          (upload['data'] as Map<String, dynamic>)['imageUrl'] as String;
      await client.patch(
        '/branches/${widget.branch.id}',
        token: token,
        body: {'imageUrl': url},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu ảnh chi nhánh')));
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sửa ảnh chi nhánh')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.branch.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(widget.branch.address),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _image == null
              ? AppImage(
                  source: widget.branch.imageUrl ?? '',
                  fallback: const Icon(Icons.store_outlined, size: 64),
                )
              : Image.file(File(_image!.path), fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pick,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Chọn ảnh'),
        ),
        if (_image != null)
          OutlinedButton.icon(
            onPressed: _saving ? null : _crop,
            icon: const Icon(Icons.crop),
            label: const Text('Cắt ảnh theo khung 16:9'),
          ),
        const Text('Ảnh JPEG, PNG hoặc WebP, tối đa 5 MB.'),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _image == null || _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu...' : 'Lưu ảnh'),
        ),
      ],
    ),
  );
}
