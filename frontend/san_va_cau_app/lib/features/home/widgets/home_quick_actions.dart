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
            'Khám phá nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                _QuickActionTile(
                  icon: Symbols.calendar_month_rounded,
                  title: 'Đặt sân',
                  accentColor: AppColors.primary,
                  backgroundColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  textColor: Colors.white,
                  isPrimary: true,
                  onTap: onBookCourtPressed,
                ),
                const SizedBox(width: 6),
                _QuickActionTile(
                  icon: Symbols.shopping_bag_rounded,
                  title: 'Mua sắm',
                  accentColor: const Color(0xFFF97316),
                  backgroundColor: const Color(0xFFFFF1E8),
                  borderColor: const Color(0xFFFDBA74),
                  textColor: const Color(0xFF9A3412),
                  onTap: onViewProductsPressed,
                ),
                const SizedBox(width: 6),
                _QuickActionTile(
                  icon: Symbols.design_services_rounded,
                  title: 'Dịch vụ\nvợt',
                  accentColor: const Color(0xFF4F46E5),
                  backgroundColor: const Color(0xFFEEF2FF),
                  borderColor: const Color(0xFFA5B4FC),
                  textColor: const Color(0xFF3730A3),
                  onTap: onRacketServicePressed,
                ),
                const SizedBox(width: 6),
                _QuickActionTile(
                  icon: Symbols.storefront_rounded,
                  title: 'Chi nhánh',
                  accentColor: const Color(0xFF0891B2),
                  backgroundColor: const Color(0xFFECFEFF),
                  borderColor: const Color(0xFF67E8F9),
                  textColor: const Color(0xFF155E75),
                  onTap: onViewBranchesPressed,
                ),
              ],
            ),
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
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isPrimary;

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 112),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? AppColors.primary
                  : widget.backgroundColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(
                    alpha: widget.isPrimary ? 0.28 : 0.15,
                  ),
                  blurRadius: widget.isPrimary ? 14 : 8,
                  offset: Offset(0, widget.isPrimary ? 6 : 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: widget.onTap,
                onHighlightChanged: (value) {
                  if (_isPressed == value) return;
                  setState(() => _isPressed = value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.isPrimary
                              ? Colors.white.withValues(alpha: 0.18)
                              : widget.accentColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 25,
                          fill: 0,
                          weight: 520,
                          opticalSize: 24,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: widget.isPrimary
                                  ? Colors.white
                                  : widget.textColor,
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
