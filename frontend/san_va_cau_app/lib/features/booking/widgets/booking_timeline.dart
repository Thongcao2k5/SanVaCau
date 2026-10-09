import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/court.dart';

class CourtSchedule {
  const CourtSchedule({
    required this.court,
    required this.slots,
    this.hasError = false,
  });
  final Court court;
  final List<BookingSlot> slots;
  final bool hasError;
}

class BookingTimeline extends StatelessWidget {
  const BookingTimeline({
    super.key,
    required this.schedules,
    required this.date,
    required this.selectedCourtIds,
    required this.selectedSlotKeys,
    this.zoom = 1,
    this.onSlotTap,
    this.onCourtInfo,
    this.onRetry,
  });

  final List<CourtSchedule> schedules;
  final DateTime date;
  final Set<String> selectedCourtIds;
  final Set<String> selectedSlotKeys;
  final double zoom;
  final void Function(Court court, BookingSlot slot)? onSlotTap;
  final ValueChanged<Court>? onCourtInfo;
  final VoidCallback? onRetry;
  static const _rowHeight = 64.0;
  static const _labelWidth = 88.0;
  static const _headerHeight = 40.0;

  int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  bool _past(BookingSlot slot) => DateTime(
    date.year,
    date.month,
    date.day,
    _minutes(slot.startTime) ~/ 60,
    _minutes(slot.startTime) % 60,
  ).isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final boundaries = <int>{};
    for (final schedule in schedules) {
      for (final slot in schedule.slots) {
        boundaries.add(_minutes(slot.startTime));
        boundaries.add(_minutes(slot.endTime));
      }
    }
    if (boundaries.isEmpty) {
      final failed = schedules.any((schedule) => schedule.hasError);
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              failed
                  ? 'Không thể tải khung giờ.'
                  : 'Các sân chưa có bảng giá khung giờ.',
            ),
            if (failed)
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    final sorted = boundaries.toList()..sort();
    final start = sorted.first;
    final end = sorted.last;
    final pixelsPerMinute = 1.7 * zoom;
    final width = (end - start) * pixelsPerMinute;
    final ticks = <int>[start];
    for (int tick = ((start ~/ 30) + 1) * 30; tick < end; tick += 30) {
      ticks.add(tick);
    }
    ticks.add(end);
    final height = _headerHeight + schedules.length * _rowHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _labelWidth,
          child: Column(
            children: [
              Container(
                height: _headerHeight,
                alignment: Alignment.center,
                color: AppColors.primarySoft,
                child: const Text(
                  'Sân / Giờ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              for (final schedule in schedules)
                Container(
                  height: _rowHeight,
                  decoration: BoxDecoration(
                    color: selectedCourtIds.contains(schedule.court.id)
                        ? AppColors.primarySoft
                        : AppColors.surface,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderMuted),
                      right: BorderSide(color: AppColors.borderMuted),
                    ),
                  ),
                  child: InkWell(
                    onTap: onCourtInfo == null
                        ? null
                        : () => onCourtInfo!(schedule.court),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            schedule.court.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width + 36,
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _headerHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(color: AppColors.primarySoft),
                        ),
                        for (final tick in ticks)
                          Positioned(
                            left: (tick - start) * pixelsPerMinute,
                            top: 10,
                            child: Text(
                              _time(tick),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final schedule in schedules)
                    SizedBox(
                      width: width,
                      height: _rowHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF9CA3AF),
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.borderMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (schedule.hasError)
                            Positioned.fill(
                              child: Center(
                                child: TextButton(
                                  onPressed: onRetry,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Lỗi tải lịch • Thử lại'),
                                ),
                              ),
                            )
                          else ...[
                            for (final slot in schedule.slots)
                              _cell(
                                schedule.court,
                                slot,
                                start,
                                pixelsPerMinute,
                              ),
                            for (final tick in ticks)
                              Positioned(
                                left: (tick - start) * pixelsPerMinute,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: .5,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(
    Court court,
    BookingSlot slot,
    int start,
    double pixelsPerMinute,
  ) {
    final isPast = _past(slot);
    final selected =
        selectedCourtIds.contains(court.id) &&
        selectedSlotKeys.contains('${court.id}:${slot.timeSlotId}');
    final disabled = slot.isBooked || isPast || court.status != 'ACTIVE';
    final color = slot.isBooked
        ? AppColors.info
        : disabled
        ? const Color(0xFF9CA3AF)
        : selected
        ? AppColors.primary
        : Colors.white;
    final state = slot.isBooked
        ? 'Đã đặt'
        : disabled
        ? 'Khóa'
        : selected
        ? 'Đang chọn'
        : 'Trống';
    final label =
        '${court.name}, ${_time(_minutes(slot.startTime))} – ${_time(_minutes(slot.endTime))}, $state';
    return Positioned(
      left: (_minutes(slot.startTime) - start) * pixelsPerMinute,
      top: 0,
      bottom: 0,
      width:
          (_minutes(slot.endTime) - _minutes(slot.startTime)) * pixelsPerMinute,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        enabled: !disabled && onSlotTap != null,
        child: Tooltip(
          message: '$label • ${slot.price.toStringAsFixed(0)} đ',
          child: Material(
            color: color,
            child: InkWell(
              key: ValueKey('slot-${court.id}-${slot.timeSlotId}'),
              onTap: disabled || onSlotTap == null
                  ? null
                  : () => onSlotTap!(court, slot),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryDark
                        : const Color(0xFFCBD5E1),
                    width: selected ? 2 : .5,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : slot.isBooked
                    ? const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineLegend extends StatelessWidget {
  const TimelineLegend({super.key, required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}
