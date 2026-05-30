import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class MonthCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool Function(DateTime) hasLogs;

  const MonthCalendar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.hasLogs,
  }) : super(key: key);

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.month != widget.selectedDate.month ||
        oldWidget.selectedDate.year != widget.selectedDate.year) {
      _displayedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    // Weekday 1 is Monday, 7 is Sunday
    final startOffset = firstDayOfMonth.weekday - 1;
    
    final totalCells = ((daysInMonth + startOffset) / 7).ceil() * 7;
    
    final List<String> weekDays = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
                color: AppTheme.primary,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_displayedMonth),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              
              // Empty cells before start of month or after end of month
              if (index < startOffset || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              
              final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
              final isSelected = date.year == widget.selectedDate.year &&
                  date.month == widget.selectedDate.month &&
                  date.day == widget.selectedDate.day;
              
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
                  
              final hasLogs = widget.hasLogs(date);

              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : (isToday ? AppTheme.primaryLight.withOpacity(0.2) : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday && !isSelected ? Border.all(color: AppTheme.primaryLight) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: hasLogs ? AppTheme.success : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
