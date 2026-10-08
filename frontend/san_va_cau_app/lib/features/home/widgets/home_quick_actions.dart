import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    required this.onBookCourtPressed,
    required this.onViewProductsPressed,
    required this.onRacketServicePressed,
    required this.onViewBranchesPressed,
    super.key,
  });

  final VoidCallback onBookCourtPressed;
  final VoidCallback onViewProductsPressed;
  final VoidCallback onRacketServicePressed;
  final VoidCallback onViewBranchesPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiện ích',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _QuickActionTile(
                icon: Symbols.event_available_rounded,
                title: 'Đặt sân',
                accentColor: AppColors.primary,
                onTap: onBookCourtPressed,
              ),
              _QuickActionTile(
                icon: Symbols.shopping_bag_rounded,
                title: 'Mua sắm',
                accentColor: const Color(0xFFF97316),
                onTap: onViewProductsPressed,
              ),
              _QuickActionTile(
                icon: Symbols.sports_tennis_rounded,
                title: 'Dịch vụ vợt',
                accentColor: const Color(0xFF4F46E5),
                onTap: onRacketServicePressed,
              ),
              _QuickActionTile(
                icon: Symbols.location_on_rounded,
                title: 'Chi nhánh',
                accentColor: const Color(0xFF0891B2),
                onTap: onViewBranchesPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: widget.title.replaceAll('\n', ' '),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_isPressed == value) return;
                setState(() => _isPressed = value);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.accentColor,
                          size: 25,
                          fill: 0,
                          weight: 480,
                          opticalSize: 24,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
