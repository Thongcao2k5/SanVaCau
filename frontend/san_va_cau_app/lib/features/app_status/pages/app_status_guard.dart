import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_util.dart';
import '../../main/main_shell.dart';
import '../data/app_status_api.dart';
import '../models/app_status.dart';

class AppStatusGuard extends StatefulWidget {
  const AppStatusGuard({super.key});

  @override
  State<AppStatusGuard> createState() => _AppStatusGuardState();
}

class _AppStatusGuardState extends State<AppStatusGuard> {
  final AppStatusApi _api = AppStatusApi();
  AppStatus? _status;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final version = '1.0.0';

      final status = await _api.getAppStatus(platform, version);
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể kiểm tra phiên bản mới')),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_status == null || _error != null) {
      return const MainShell();
    }

    if (_status!.maintenanceMode) {
      return _MaintenanceScreen(
        message: _status!.maintenanceMessage ?? 'Hệ thống đang bảo trì.',
        onRetry: _checkStatus,
      );
    }

    if (_status!.updateRequired) {
      return _ForceUpdateScreen(
        message: _status!.updateMessage ?? 'Vui lòng cập nhật phiên bản mới.',
        storeUrl: _status!.storeUrl,
      );
    }

    return const MainShell();
  }
}

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _StatusPageContent(
        icon: Icons.build_circle_outlined,
        title: 'Bảo trì hệ thống',
        message: message,
        actionLabel: 'Thử lại',
        onAction: onRetry,
      ),
    );
  }
}

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen({required this.message, this.storeUrl});
  final String message;
  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _StatusPageContent(
        icon: Icons.system_update_alt,
        title: 'Cập nhật bắt buộc',
        message: message,
        actionLabel: 'Cập nhật ngay',
        onAction: () {
          if (storeUrl != null && storeUrl!.isNotEmpty) {
            openUrlSafely(context, storeUrl!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link cập nhật sẽ có trong thời gian tới'),
              ),
            );
          }
        },
      ),
    );
  }
}

class _StatusPageContent extends StatelessWidget {
  const _StatusPageContent({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
