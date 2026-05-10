// lib/screens/calendar_view/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants.dart';
import '../../core/formatter.dart';
import '../../providers/history_provider.dart';
import '../today_entry/today_entry_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay   = DateTime.now();
  DateTime _selectedDay  = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth(_focusedDay));
  }

  void _loadMonth(DateTime date) {
    context.read<HistoryProvider>().loadMonth(date.year, date.month);
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay  = focused;
    });
    final hasEntry = context.read<HistoryProvider>().hasEntryForDate(selected);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodayEntryScreen(date: selected),
      ),
    ).then((_) {
      // Refresh calendar after returning from entry
      context.read<HistoryProvider>().invalidateCache();
      _loadMonth(_focusedDay);
    });
  }

  void _onPageChanged(DateTime focused) {
    setState(() => _focusedDay = focused);
    _loadMonth(focused);
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final scheme  = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Monthly Summary',
            onPressed: () => Navigator.pushNamed(context, kRouteMonthlySummary),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, kRouteSettings),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Calendar ─────────────────────────────────────
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: TableCalendar(
              firstDay:      DateTime(2020),
              lastDay:       DateTime(2030),
              focusedDay:    _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              calendarFormat: _format,
              onFormatChanged: (f) => setState(() => _format = f),
              onDaySelected:   _onDaySelected,
              onPageChanged:   _onPageChanged,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  border:       Border.all(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(color: kPrimaryColor),
                titleCentered:        true,
                titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(
                  color: kPrimaryColor, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.3), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(
                    color: kAccentColor, fontWeight: FontWeight.bold),
                markerDecoration: const BoxDecoration(
                  color: kGreenColor, shape: BoxShape.circle),
                markerSize: 6,
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (ctx, day, events) {
                  if (history.hasEntryForDate(day)) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: kGreenColor, shape: BoxShape.circle),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),

          // ── Legend ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(width: 10, height: 10,
                    decoration: const BoxDecoration(
                        color: kGreenColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Entry recorded',
                    style: TextStyle(fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.6))),
                const SizedBox(width: 20),
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: kAccentColor.withOpacity(0.3),
                        shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Today',
                    style: TextStyle(fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // ── Recent entries list ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('This Month',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: scheme.onSurface)),
                const Spacer(),
                if (history.isLoading)
                  const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),

          Expanded(
            child: history.datesWithEntries.isEmpty && !history.isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_outlined,
                            size: 48,
                            color: scheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('No entries this month',
                            style: TextStyle(
                                color: scheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: history.datesWithEntries
                        .toList()
                        .reversed
                        .map((date) => _EntryTile(date: date))
                        .toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodayEntryScreen()),
        ).then((_) {
          context.read<HistoryProvider>().invalidateCache();
          _loadMonth(_focusedDay);
        }),
        backgroundColor: kPrimaryColor,
        icon:  const Icon(Icons.add, color: Colors.white),
        label: const Text("Today's Entry",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DateTime date;
  const _EntryTile({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(date, DateTime.now());
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday
              ? kPrimaryColor.withOpacity(0.4)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color:        kPrimaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  fontSize: 18),
            ),
          ),
        ),
        title: Text(
          RojMedFormatter.dateDisplay(date),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          isToday ? 'Today' : _weekdayName(date.weekday),
          style: TextStyle(fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: kPrimaryColor),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TodayEntryScreen(date: date)),
        ).then((_) {
          context.read<HistoryProvider>().invalidateCache();
          context.read<HistoryProvider>().loadMonth(date.year, date.month);
        }),
      ),
    );
  }

  String _weekdayName(int w) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(w - 1).clamp(0, 6)];
  }
}
