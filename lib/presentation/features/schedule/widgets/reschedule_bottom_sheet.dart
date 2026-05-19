import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_extensions.dart';
import '../../../../data/models/lesson_dto.dart';
import '../../../../l10n/app_localizations.dart';

class SlotInfo {
  final int number;
  final String start;
  final String end;

  const SlotInfo(this.number, this.start, this.end);
}

const List<SlotInfo> universitySlots = [
  SlotInfo(1, '08:30', '09:50'),
  SlotInfo(2, '10:00', '11:20'),
  SlotInfo(3, '11:40', '13:00'),
  SlotInfo(4, '13:10', '14:30'),
  SlotInfo(5, '14:40', '16:00'),
  SlotInfo(6, '16:10', '17:30'),
];

class RescheduleBottomSheet extends StatefulWidget {
  final LessonDto lesson;

  const RescheduleBottomSheet({super.key, required this.lesson});

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _error;
  List<LessonDto> _groupLessons = [];

  late List<DateTime> _availableDates;
  DateTime? _selectedDate;
  int? _selectedSlotNumber;

  @override
  void initState() {
    super.initState();
    _initDates();
    _loadGroupSchedule();
  }

  void _initDates() {
    final today = DateTime.now();
    final dates = <DateTime>[];
    var current = today.add(const Duration(days: 1)); // start from tomorrow

    // Collect next 10 workdays (excluding Saturday and Sunday)
    while (dates.length < 10) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    _availableDates = dates;
    _selectedDate = dates.first;
  }

  Future<void> _loadGroupSchedule() async {
    try {
      final snapshot = await _firestore
          .collection('schedule')
          .where('groupId', isEqualTo: widget.lesson.groupId)
          .get();

      if (mounted) {
        setState(() {
          _groupLessons = snapshot.docs
              .map((doc) => LessonDto.fromJson(doc.data()))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool _isSlotFree(int slotNumber, DateTime date) {
    final isNumerator = date.isNumeratorWeek;
    final weekday = date.weekday;

    for (final l in _groupLessons) {
      if (l.dayOfWeek == weekday && l.lessonNumber == slotNumber) {
        final wt = l.weekType.toLowerCase();
        if (wt.isEmpty || wt == 'all' || wt == 'both' || wt == 'always') {
          return false;
        }
        if (isNumerator && wt == 'numerator') {
          return false;
        }
        if (!isNumerator && wt == 'denominator') {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _confirmReschedule() async {
    if (_selectedDate == null || _selectedSlotNumber == null) return;

    final targetSlot = universitySlots.firstWhere((s) => s.number == _selectedSlotNumber);
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
    });

    try {
      final oldDay = _weekdayLabel(context, widget.lesson.dayOfWeek);
      final newDay = _weekdayLabel(context, _selectedDate!.weekday);
      final newDateStr = DateFormat('dd.MM.yyyy').format(_selectedDate!);

      // 1. Update lesson document in Firestore
      await _firestore.collection('schedule').doc(widget.lesson.id).update({
        'dayOfWeek': _selectedDate!.weekday,
        'lessonNumber': _selectedSlotNumber,
        'timeStart': targetSlot.start,
        'timeEnd': targetSlot.end,
        'isModification': true,
      });

      // 2. Create notification inside Firestore
      await _firestore.collection('notifications').add({
        'groupId': widget.lesson.groupId,
        'teacherName': widget.lesson.teacherName,
        'subjectName': widget.lesson.subjectName,
        'oldDateText': '$oldDay, пара №${widget.lesson.lessonNumber}',
        'newDateText': '$newDay ($newDateStr), пара №$_selectedSlotNumber (${targetSlot.start}-${targetSlot.end})',
        'timeStart': targetSlot.start,
        'timeEnd': targetSlot.end,
        'createdAt': FieldValue.serverTimestamp(),
        'isReadBy': {},
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sent),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _weekdayLabel(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    return switch (weekday) {
      1 => l10n.monday,
      2 => l10n.tuesday,
      3 => l10n.wednesday,
      4 => l10n.thursday,
      5 => l10n.friday,
      6 => l10n.saturday,
      7 => l10n.sunday,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Перенесення пари',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.lesson.subjectName} (${widget.lesson.type})',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Для групи: ${widget.lesson.groupId}',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            )
          else ...[
            // Horizontal Date picker
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Text(
                'Оберіть дату:',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableDates.length,
                itemBuilder: (context, index) {
                  final date = _availableDates[index];
                  final isSelected = _selectedDate != null && DateUtils.isSameDay(date, _selectedDate!);
                  final parityText = date.isNumeratorWeek ? 'чисельник' : 'знаменник';
                  final dateStr = DateFormat('dd.MM').format(date);
                  final weekdayStr = DateFormat('E', 'uk_UA').format(date).toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedDate = date;
                        _selectedSlotNumber = null;
                      }),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdayStr,
                              style: textTheme.labelSmall?.copyWith(
                                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: textTheme.titleMedium?.copyWith(
                                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              parityText,
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 8,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                    : colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Time Slots Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
              child: Text(
                'Вільні вікна та пари:',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            // Vertical list of Slots
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: universitySlots.length,
                  itemBuilder: (context, index) {
                    final slot = universitySlots[index];
                    final isFree = _isSlotFree(slot.number, _selectedDate!);
                    final isSelected = _selectedSlotNumber == slot.number;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: isFree
                            ? () => setState(() => _selectedSlotNumber = slot.number)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !isFree
                                ? colorScheme.surfaceContainerLowest
                                : isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : isFree
                                      ? colorScheme.outlineVariant
                                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isFree
                                    ? isSelected
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline
                                    : Icons.lock_clock,
                                color: isFree
                                    ? isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Пара №${slot.number}',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isFree
                                            ? isSelected
                                                ? colorScheme.onPrimaryContainer
                                                : colorScheme.onSurface
                                            : colorScheme.outline,
                                      ),
                                    ),
                                    Text(
                                      '${slot.start} - ${slot.end}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFree
                                      ? isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isFree ? 'Вільно' : 'Зайнято',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isFree
                                        ? isSelected
                                            ? colorScheme.primaryContainer
                                            : colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedSlotNumber != null ? _confirmReschedule : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Підтвердити перенесення',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
