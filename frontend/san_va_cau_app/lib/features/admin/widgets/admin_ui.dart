import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.dark = true,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AdminTheme.textPrimary;
    final secondary = dark
        ? AdminTheme.navigationMuted
        : AdminTheme.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        color: dark ? AdminTheme.graphite : AdminTheme.canvas,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AdminTheme.cardRadius),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: secondary, height: 1.35),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AdminTheme.cardRadius,
    this.color = AdminTheme.surface,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AdminTheme.border),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AdminIconBox extends StatelessWidget {
  const AdminIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

enum AdminStatusTone { neutral, info, success, warning, danger }

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.label,
    this.tone = AdminStatusTone.neutral,
  });

  final String label;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (foreground, background, icon) = switch (tone) {
      AdminStatusTone.info => (
        AdminTheme.info,
        AdminTheme.info.withValues(alpha: 0.1),
        Icons.info_outline_rounded,
      ),
      AdminStatusTone.success => (
        AdminTheme.success,
        AdminTheme.success.withValues(alpha: 0.1),
        Icons.check_circle_outline_rounded,
      ),
      AdminStatusTone.warning => (
        AdminTheme.warning,
        AdminTheme.warning.withValues(alpha: 0.1),
        Icons.schedule_rounded,
      ),
      AdminStatusTone.danger => (
        AdminTheme.primary,
        AdminTheme.primary.withValues(alpha: 0.1),
        Icons.cancel_outlined,
      ),
      AdminStatusTone.neutral => (
        AdminTheme.textSecondary,
        AdminTheme.canvas,
        Icons.circle_outlined,
      ),
    };
    return Semantics(
      label: 'Trạng thái: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStateView extends StatelessWidget {
  const AdminStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminIconBox(icon: icon, color: AdminTheme.primary, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AdminTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AdminTheme.textSecondary, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: AdminTheme.touchTarget,
                child: OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
