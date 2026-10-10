import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

class BranchImageCropPage extends StatefulWidget {
  const BranchImageCropPage({super.key, required this.image});
  final XFile image;
  @override
  State<BranchImageCropPage> createState() => _BranchImageCropPageState();
}

class _BranchImageCropPageState extends State<BranchImageCropPage> {
  final _boundaryKey = GlobalKey();
  final _transform = TransformationController();
  Future<void>? _loaded;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loaded ??= precacheImage(
      FileImage(File(widget.image.path)),
      context,
      onError: (_, _) {
        if (mounted) setState(() => _error = 'Không thể đọc ảnh này.');
      },
    );
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    ui.Image? output;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      output = await boundary.toImage(pixelRatio: 1200 / boundary.size.width);
      final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Image encoding failed');
      final file = File(
        '${File(widget.image.path).parent.path}${Platform.pathSeparator}branch-crop-${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (mounted) Navigator.of(context).pop(XFile(file.path));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể cắt ảnh. Vui lòng thử lại.');
      }
    } finally {
      output?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cắt ảnh chi nhánh')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<void>(
        future: _loaded,
        builder: (context, snapshot) {
          final ready =
              snapshot.connectionState == ConnectionState.done &&
              _error == null;
          return Column(
            children: [
              const Text(
                'Dùng hai ngón tay để phóng to, kéo ảnh để chọn vùng muốn giữ trong khung 16:9.',
              ),
              const Spacer(),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: ClipRect(
                        child: ColoredBox(
                          color: Colors.white,
                          child: InteractiveViewer(
                            transformationController: _transform,
                            minScale: 1,
                            maxScale: 12,
                            child: SizedBox.expand(
                              child: Image.file(
                                File(widget.image.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _transform.value = Matrix4.identity(),
                child: const Text('Đặt lại vùng cắt'),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !ready || _busy ? null : _apply,
                  child: Text(_busy ? 'Đang xử lý...' : 'Dùng ảnh đã cắt'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    ),
  );
}
