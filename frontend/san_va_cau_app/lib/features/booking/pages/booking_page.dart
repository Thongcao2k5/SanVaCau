import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/booking_api.dart';
import '../models/court.dart';
import 'court_detail_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final BranchApi _branchApi = BranchApi();
  final BookingApi _bookingApi = BookingApi();
  late Future<List<Branch>> _branchesFuture;
  Future<List<Court>>? _courtsFuture;
  Future<List<BookingSlot>>? _slotsFuture;
  Branch? _selectedBranch;
  Court? _selectedCourt;
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedSlotIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _branchesFuture = _branchApi.getBranches();
  }

  String get _dateText {
    final year = _selectedDate.year.toString().padLeft(4, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _selectBranch(Branch branch) {
    setState(() {
      _selectedBranch = branch;
      _selectedCourt = null;
      _selectedSlotIds.clear();
      _courtsFuture = _bookingApi.getCourts(branchId: branch.id);
      _slotsFuture = null;
    });
  }

  void _selectCourt(Court court) {
    setState(() {
      _selectedCourt = court;
      _selectedSlotIds.clear();
      _slotsFuture = _bookingApi.getAvailability(
        courtId: court.id,
        date: _dateText,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _selectedSlotIds.clear();
      if (_selectedCourt != null) {
        _slotsFuture = _bookingApi.getAvailability(
          courtId: _selectedCourt!.id,
          date: _dateText,
        );
      }
    });
  }

  Future<void> _submitBooking() async {
    final court = _selectedCourt;

    if (court == null || _selectedSlotIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn sân và ít nhất một khung giờ.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _bookingApi.createBooking(
        courtId: court.id,
        bookingDate: _dateText,
        timeSlotIds: _selectedSlotIds.toList(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đặt sân thành công.')));

      setState(() {
        _selectedSlotIds.clear();
        _slotsFuture = _bookingApi.getAvailability(
          courtId: court.id,
          date: _dateText,
        );
      });
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt sân')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _BookingSummaryCard(
            branchName: _selectedBranch?.name ?? 'Chưa chọn chi nhánh',
            courtName: _selectedCourt?.name ?? 'Chưa chọn sân',
            dateText: _dateText,
            selectedCount: _selectedSlotIds.length,
          ),
          const SizedBox(height: 20),
          _BookingStepCard(
            step: '01',
            title: 'Chọn chi nhánh',
            child: FutureBuilder<List<Branch>>(
              future: _branchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return _InlineError(
                    message: 'Không thể tải chi nhánh',
                    onRetry: () {
                      setState(() {
                        _branchesFuture = _branchApi.getBranches();
                      });
                    },
                  );
                }

                final branches = snapshot.data ?? const <Branch>[];

                return _ChoiceWrap<Branch>(
                  items: branches,
                  selectedItem: _selectedBranch,
                  labelOf: (branch) => branch.name,
                  onSelected: _selectBranch,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _BookingStepCard(
            step: '02',
            title: 'Chọn sân',
            child: _courtsFuture == null
                ? const _HintText('Chọn chi nhánh trước để xem danh sách sân.')
                : FutureBuilder<List<Court>>(
                    future: _courtsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _HintText('Không thể tải danh sách sân.');
                      }

                      final courts = snapshot.data ?? const <Court>[];

                      if (courts.isEmpty) {
                        return const _HintText(
                          'Chi nhánh này chưa có sân hoạt động.',
                        );
                      }

                      return _ChoiceWrap<Court>(
                        items: courts,
                        selectedItem: _selectedCourt,
                        labelOf: (court) => court.name,
                        onSelected: _selectCourt,
                        onInfoTapped: (court) async {
                          final returnedCourt = await Navigator.of(context)
                              .push<Court>(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourtDetailPage(court: court),
                                ),
                              );
                          if (returnedCourt != null) {
                            _selectCourt(returnedCourt);
                          }
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          _BookingStepCard(
            step: '03',
            title: 'Chọn ngày',
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dateText),
            ),
          ),
          const SizedBox(height: 20),
          _BookingStepCard(
            step: '04',
            title: 'Chọn khung giờ',
            child: _slotsFuture == null
                ? const _HintText('Chọn sân để xem khung giờ còn trống.')
                : FutureBuilder<List<BookingSlot>>(
                    future: _slotsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return const _HintText('Không thể tải khung giờ.');
                      }

                      final slots = snapshot.data ?? const <BookingSlot>[];

                      if (slots.isEmpty) {
                        return const _HintText(
                          'Sân này chưa có bảng giá khung giờ.',
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: slots.map((slot) {
                          final isSelected = _selectedSlotIds.contains(
                            slot.timeSlotId,
                          );

                          final startTime = slot.startTime.length >= 5
                              ? slot.startTime.substring(0, 5)
                              : slot.startTime;
                          final endTime = slot.endTime.length >= 5
                              ? slot.endTime.substring(0, 5)
                              : slot.endTime;

                          return FilterChip(
                            selected: isSelected,
                            label: Text('$startTime-$endTime'),
                            avatar: slot.isBooked
                                ? const Icon(Icons.lock_outline, size: 16)
                                : null,
                            onSelected: slot.isBooked
                                ? null
                                : (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedSlotIds.add(slot.timeSlotId);
                                      } else {
                                        _selectedSlotIds.remove(
                                          slot.timeSlotId,
                                        );
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderMuted)),
          ),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitBooking,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_isSubmitting ? 'Đang đặt sân...' : 'Xác nhận đặt sân'),
          ),
        ),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.branchName,
    required this.courtName,
    required this.dateText,
    required this.selectedCount,
  });

  final String branchName;
  final String courtName;
  final String dateText;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_tennis, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$branchName • $courtName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateText • $selectedCount khung giờ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingStepCard extends StatelessWidget {
  const _BookingStepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.items,
    required this.selectedItem,
    required this.labelOf,
    required this.onSelected,
    this.onInfoTapped,
  });

  final List<T> items;
  final T? selectedItem;
  final String Function(T item) labelOf;
  final ValueChanged<T> onSelected;
  final ValueChanged<T>? onInfoTapped;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        if (onInfoTapped != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(
                selected: item == selectedItem,
                label: Text(labelOf(item)),
                onSelected: (_) => onSelected(item),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => onInfoTapped!(item),
                tooltip: 'Xem chi tiết sân',
              ),
              const SizedBox(width: 4),
            ],
          );
        }
        return ChoiceChip(
          selected: item == selectedItem,
          label: Text(labelOf(item)),
          onSelected: (_) => onSelected(item),
        );
      }).toList(),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: AppColors.textSecondary, height: 1.4),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _HintText(message)),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
