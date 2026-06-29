import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum CalendarMode { monthly, yearly }

class CustomCalendar extends StatefulWidget {
  final CalendarMode initialMode;
  final DateTime? initialDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final Map<DateTime, Color>? monthlyIndicators;
  final Map<int, Color>? yearlyIndicators;
  final double height;
  final double width;
  final int startDay;
  final Function(DateTime)? onDateChanged;
  final Function(DateTime)? onDaySelected;
  final Function(int)? onMonthSelected;

  const CustomCalendar({
    super.key,
    this.initialMode = CalendarMode.monthly,
    this.initialDate,
    this.periodStart,
    this.periodEnd,
    this.monthlyIndicators,
    this.yearlyIndicators,
    this.height = 400,
    this.width = 350,
    this.startDay = 1,
    this.onDateChanged,
    this.onDaySelected,
    this.onMonthSelected,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late CalendarMode _mode;
  late DateTime _currentDate;

  bool get _hasBudgetPeriod =>
      widget.periodStart != null && widget.periodEnd != null;

  DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _dayEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  bool _isInBudgetPeriod(DateTime date) {
    if (!_hasBudgetPeriod) return false;
    final day = _dayStart(date);
    return !day.isBefore(_dayStart(widget.periodStart!)) &&
        !day.isAfter(_dayEnd(widget.periodEnd!));
  }

  bool _monthOverlapsBudget(int year, int month) {
    if (!_hasBudgetPeriod) return false;
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    return !monthEnd.isBefore(_dayStart(widget.periodStart!)) &&
        !monthStart.isAfter(_dayEnd(widget.periodEnd!));
  }

  DateTime _clampToBudgetPeriod(DateTime date) {
    if (!_hasBudgetPeriod) return date;
    final day = _dayStart(date);
    if (day.isBefore(_dayStart(widget.periodStart!))) {
      return _dayStart(widget.periodStart!);
    }
    if (day.isAfter(_dayEnd(widget.periodEnd!))) {
      return _dayStart(widget.periodEnd!);
    }
    return day;
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _currentDate = _clampToBudgetPeriod(
      widget.initialDate ?? widget.periodStart ?? DateTime.now(),
    );
  }

  @override
  void didUpdateWidget(CustomCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periodStart != oldWidget.periodStart ||
        widget.periodEnd != oldWidget.periodEnd) {
      _currentDate = _clampToBudgetPeriod(_currentDate);
    }
  }

  bool get _canGoNext {
    if (!_hasBudgetPeriod) return true;
    if (_mode == CalendarMode.monthly) {
      final nextMonth = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      final periodEndMonth =
          DateTime(widget.periodEnd!.year, widget.periodEnd!.month, 1);
      return !nextMonth.isAfter(periodEndMonth);
    }
    return _currentDate.year < widget.periodEnd!.year;
  }

  bool get _canGoPrevious {
    if (!_hasBudgetPeriod) return true;
    if (_mode == CalendarMode.monthly) {
      final prevMonth = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      final periodStartMonth =
          DateTime(widget.periodStart!.year, widget.periodStart!.month, 1);
      return !prevMonth.isBefore(periodStartMonth);
    }
    return _currentDate.year > widget.periodStart!.year;
  }

  void _next() {
    if (!_canGoNext) return;
    setState(() {
      if (_mode == CalendarMode.monthly) {
        _currentDate =
            DateTime(_currentDate.year, _currentDate.month + 1, _currentDate.day);
      } else {
        _currentDate = DateTime(_currentDate.year + 1);
      }
      _currentDate = _clampToBudgetPeriod(_currentDate);
    });
    widget.onDateChanged?.call(_currentDate);
  }

  void _previous() {
    if (!_canGoPrevious) return;
    setState(() {
      if (_mode == CalendarMode.monthly) {
        _currentDate =
            DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
      } else {
        _currentDate = DateTime(_currentDate.year - 1);
      }
      _currentDate = _clampToBudgetPeriod(_currentDate);
    });
    widget.onDateChanged?.call(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF262450),
        border: Border.all(color: const Color(0xFF524EAE), width: 1),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent,
            blurRadius: 100,
            offset: const Offset(10, -10),
            spreadRadius: -40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (_hasBudgetPeriod) ...[
            const SizedBox(height: 6),
            Text(
              '${DateFormat.yMMMd().format(widget.periodStart!)} – '
              '${DateFormat.yMMMd().format(widget.periodEnd!)}',
              style: AppTextStyles.body1.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Create a budget to view calendar spending',
                style: AppTextStyles.body1.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),
          _mode == CalendarMode.monthly ? _buildMonthlyView() : _buildYearlyView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 14, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _canGoPrevious ? _previous : null,
                child: Icon(
                  Icons.arrow_left,
                  size: 20,
                  color: _canGoPrevious ? AppColors.accent : Colors.white24,
                ),
              ),
              Text(
                _mode == CalendarMode.monthly
                    ? DateFormat.yMMMM().format(_currentDate)
                    : '${_currentDate.year}',
                style: AppTextStyles.midBody1,
              ),
              GestureDetector(
                onTap: _canGoNext ? _next : null,
                child: Icon(
                  Icons.arrow_right,
                  size: 20,
                  color: _canGoNext ? AppColors.accent : Colors.white24,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildToggleButton(CalendarMode.monthly, 'Monthly'),
              _buildToggleButton(CalendarMode.yearly, 'Yearly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(CalendarMode mode, String label) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0XFF0DA6C2), Color(0XFF0E39C6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: AppTextStyles.body1),
      ),
    );
  }

  Widget _buildMonthlyView() {
    DateTime firstDayOfCycle;
    DateTime lastDayOfCycle;

    if (_hasBudgetPeriod) {
      firstDayOfCycle = _dayStart(widget.periodStart!);
      lastDayOfCycle = _dayStart(widget.periodEnd!);
    } else if (widget.startDay > 1) {
      firstDayOfCycle =
          DateTime(_currentDate.year, _currentDate.month - 1, widget.startDay);
      lastDayOfCycle = DateTime(_currentDate.year, _currentDate.month, widget.startDay)
          .subtract(const Duration(days: 1));
    } else {
      firstDayOfCycle = DateTime(_currentDate.year, _currentDate.month, 1);
      lastDayOfCycle =
          DateTime(_currentDate.year, _currentDate.month + 1, 0);
    }

    final monthStart = DateTime(_currentDate.year, _currentDate.month, 1);
    final monthEnd = DateTime(_currentDate.year, _currentDate.month + 1, 0);

    final visibleStart =
        monthStart.isBefore(firstDayOfCycle) ? firstDayOfCycle : monthStart;
    final visibleEnd = monthEnd.isAfter(lastDayOfCycle) ? lastDayOfCycle : monthEnd;

    if (visibleStart.isAfter(visibleEnd)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No days in this month for the current budget.',
            style: AppTextStyles.body1,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final weekdayOffset = (visibleStart.weekday + 6) % 7;
    final calendarStart = visibleStart.subtract(Duration(days: weekdayOffset));
    final totalDays = visibleEnd.difference(calendarStart).inDays + 1;
    final totalRows = (totalDays / 7).ceil();

    final rows = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            .map(
              (d) => Expanded(
                child: Center(child: Text(d, style: AppTextStyles.body1)),
              ),
            )
            .toList(),
      ),
    ];

    var date = calendarStart;
    for (var i = 0; i < totalRows; i++) {
      rows.add(
        Row(
          children: List.generate(7, (j) {
            final cellDate = date;
            final isActive = _hasBudgetPeriod
                ? _isInBudgetPeriod(cellDate) &&
                    cellDate.month == _currentDate.month
                : cellDate.month == _currentDate.month;

            final boxColor = isActive
                ? (widget.monthlyIndicators?[cellDate]?.withOpacity(0.6) ??
                    Colors.transparent)
                : Colors.transparent;

            final cell = GestureDetector(
              onTap: () {
                if (isActive) {
                  widget.onDaySelected?.call(cellDate);
                }
              },
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    width: 30,
                    height: 25,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '${cellDate.day}',
                      style:
                          isActive ? AppTextStyles.body1 : AppTextStyles.body3,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );

            date = date.add(const Duration(days: 1));
            return Expanded(child: Center(child: cell));
          }),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildYearlyView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthName =
            DateFormat.MMMM().format(DateTime(_currentDate.year, month, 1));
        final isActive = _hasBudgetPeriod
            ? _monthOverlapsBudget(_currentDate.year, month)
            : false;
        final boxColor = isActive
            ? (widget.yearlyIndicators?[month] ?? Colors.transparent)
            : Colors.transparent;

        return GestureDetector(
          onTap: () {
            if (isActive) {
              widget.onMonthSelected?.call(month);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? Colors.grey.shade300 : Colors.white12,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.white38,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: boxColor == Colors.transparent
                        ? (isActive ? Colors.white12 : Colors.transparent)
                        : boxColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
