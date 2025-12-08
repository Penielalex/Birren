import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum CalendarMode { monthly, yearly }

class CustomCalendar extends StatefulWidget {
  final CalendarMode initialMode;
  final DateTime? initialDate;
  final Map<DateTime, Color>? monthlyIndicators; // color per date
  final Map<int, Color>? yearlyIndicators; // color per month (1-12)
  final double height;
  final double width;

  const CustomCalendar({
    Key? key,
    this.initialMode = CalendarMode.monthly,
    this.initialDate,
    this.monthlyIndicators,
    this.yearlyIndicators,
    this.height = 400,
    this.width = 350,
  }) : super(key: key);

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late CalendarMode _mode;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _currentDate = widget.initialDate ?? DateTime.now();
  }

  void _next() {
    setState(() {
      if (_mode == CalendarMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, _currentDate.day);
      } else {
        _currentDate = DateTime(_currentDate.year + 1);
      }
    });
  }

  void _previous() {
    setState(() {
      if (_mode == CalendarMode.monthly) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
      } else {
        _currentDate = DateTime(_currentDate.year - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(


      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: Color(0xFF262450),
        border: Border.all(color: Color(0xFF524EAE), width: 1),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 100,offset: const Offset(10, -10),spreadRadius: -40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _mode == CalendarMode.monthly ? _buildMonthlyView() : _buildYearlyView(),
        ],
      )

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
                onTap: _previous,
                child: Icon(Icons.arrow_left, size: 20, color: AppColors.accent),
              ),
              Text(
                _mode == CalendarMode.monthly
                    ? DateFormat.yMMMM().format(_currentDate)
                    : '${_currentDate.year}',
                style: AppTextStyles.midBody1
              ),
              GestureDetector(
                onTap: _next,
                child: Icon(Icons.arrow_right, size: 20, color: AppColors.accent),
              ),

            ],
          ),
          // Right: Toggle buttons
          Row(
            children: [
              _buildToggleButton(CalendarMode.monthly, 'Monthly'),
              //const SizedBox(width: 6),
              _buildToggleButton(CalendarMode.yearly, 'Yearly'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToggleButton(CalendarMode mode, String label) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ?  LinearGradient(
            colors: [Color(0XFF0DA6C2), Color(0XFF0E39C6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [Colors.transparent, Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: isSelected? AppTextStyles.body1: AppTextStyles.body1,
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    // Determine the start of the month calendar (Monday)
    DateTime firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    int weekdayOffset = (firstDayOfMonth.weekday + 6) % 7; // Monday = 0
    DateTime calendarStart = firstDayOfMonth.subtract(Duration(days: weekdayOffset));

    // End date = last day of month
    DateTime lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 1).subtract(const Duration(days: 1));
    int totalDays = lastDayOfMonth.difference(calendarStart).inDays + 1;
    int totalRows = (totalDays / 7).ceil();

    List<Widget> rows = [];
    DateTime date = calendarStart;

    // Weekday labels
    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) => Expanded(
        child: Center(child: Text(d, style:AppTextStyles.body1)),
      )).toList(),
    ));

    // Calendar rows
    for (int i = 0; i < totalRows; i++) {
      rows.add(Row(
        children: List.generate(7, (j) {
          Color boxColor = widget.monthlyIndicators?[date]?.withOpacity(0.6) ?? Colors.transparent;
          bool isCurrentMonth = date.month == _currentDate.month;

          Widget cell = Column(
            children: [

              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(2),
                width: 30,
                height: 25,
                decoration: BoxDecoration(
                  color: isCurrentMonth ? boxColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                    '${date.day}',
                    style: isCurrentMonth? AppTextStyles.body1: AppTextStyles.body3

                ),
              ),
              SizedBox(height: 10,)
            ],
          );

          date = date.add(const Duration(days: 1));
          return Expanded(child: Center(child: cell));
        }),
      ));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildYearlyView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        String monthName = DateFormat.MMMM().format(DateTime(_currentDate.year, index + 1, 1));
        Color boxColor = widget.yearlyIndicators?[index + 1] ?? Colors.grey.shade300;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
