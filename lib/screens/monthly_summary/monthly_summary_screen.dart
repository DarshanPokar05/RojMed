// lib/screens/monthly_summary/monthly_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatter.dart';
import '../../providers/summary_provider.dart';
import '../../data/models/daily_entry_model.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<SummaryProvider>().loadMonth(now.year, now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<SummaryProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.current == null
              ? Center(
                  child: Text('No data',
                      style: TextStyle(color: scheme.onSurface.withOpacity(0.5))))
              : _buildBody(prov),
    );
  }

  Widget _buildBody(SummaryProvider prov) {
    final data   = prov.current!;
    final totals = data.totals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Month Navigator ───────────────────────────────
        _MonthNavigator(prov: prov, data: data),
        const SizedBox(height: 16),

        // ── Total Cards ───────────────────────────────────
        Row(children: [
          Expanded(child: _TotalCard(
            label: 'Daily Collections',
            value: RojMedFormatter.currencyCompact(totals.totalDailyCollection),
            icon:  Icons.payments_rounded,
            color: kGreenColor,
          )),
          const SizedBox(width: 10),
          Expanded(child: _TotalCard(
            label: 'Shop Spend',
            value: RojMedFormatter.currencyCompact(totals.totalShopSpend),
            icon:  Icons.store_rounded,
            color: kAccentColor,
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _TotalCard(
            label: 'Personal Spend',
            value: RojMedFormatter.currencyCompact(totals.totalPersonalSpend),
            icon:  Icons.person_rounded,
            color: kOrangeColor,
          )),
          const SizedBox(width: 10),
          Expanded(child: _TotalCard(
            label: 'Corner Numbers',
            value: '${totals.totalCornerNumbers}',
            icon:  Icons.tag_rounded,
            color: kPrimaryColor,
          )),
        ]),

        const SizedBox(height: 20),

        // ── Per-Day Breakdown ─────────────────────────────
        Row(
          children: [
            const Text('Day-by-Day Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text('${data.days.length} entries',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 10),

        if (data.days.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('No entries for this month',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
            ),
          )
        else
          _DayBreakdownTable(days: data.days),
      ],
    );
  }
}

// ── Month Navigator ───────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final SummaryProvider prov;
  final MonthlySummaryData data;
  const _MonthNavigator({required this.prov, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: prov.goToPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        Column(
          children: [
            Text(
              RojMedFormatter.monthYear(DateTime(data.year, data.month)),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, color: kPrimaryColor),
            ),
            Text('${data.days.length} entries recorded',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
        IconButton(
          onPressed: () {
            final now = DateTime.now();
            final isCurrentMonth =
                data.year == now.year && data.month == now.month;
            if (!isCurrentMonth) prov.goToNextMonth();
          },
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ── Total Card ────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;
  const _TotalCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}

// ── Day Breakdown Table ───────────────────────────────────────

class _DayBreakdownTable extends StatelessWidget {
  final List<DailyEntryModel> days;
  const _DayBreakdownTable({required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(1.2),
          },
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(color: kPrimaryColor),
              children: [
                _HeaderCell('Date'),
                _HeaderCell('Collection'),
                _HeaderCell('Shop'),
                _HeaderCell('Personal'),
                _HeaderCell('Corner'),
              ],
            ),
            // Data rows
            ...days.asMap().entries.map((e) {
              final i   = e.key;
              final day = e.value;
              final bg  = i.isEven
                  ? (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04))
                  : Colors.transparent;
              return TableRow(
                decoration: BoxDecoration(color: bg),
                children: [
                  _DataCell(RojMedFormatter.dateShort(day.entryDate), bold: true),
                  _DataCell(RojMedFormatter.currencyCompact(day.dailyCollection),
                      color: kGreenColor),
                  _DataCell(RojMedFormatter.currencyCompact(day.shopTotal),
                      color: kAccentColor),
                  _DataCell(RojMedFormatter.currencyCompact(day.personalTotal),
                      color: kOrangeColor),
                  _DataCell('${day.cornerNumber}', color: kPrimaryColor, bold: true),
                ],
              );
            }),
            // Totals row
            TableRow(
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
              ),
              children: [
                _DataCell('TOTAL', bold: true),
                _DataCell(
                  RojMedFormatter.currencyCompact(
                      days.fold(0.0, (s, d) => s + d.dailyCollection)),
                  color: kGreenColor, bold: true,
                ),
                _DataCell(
                  RojMedFormatter.currencyCompact(
                      days.fold(0.0, (s, d) => s + d.shopTotal)),
                  color: kAccentColor, bold: true,
                ),
                _DataCell(
                  RojMedFormatter.currencyCompact(
                      days.fold(0.0, (s, d) => s + d.personalTotal)),
                  color: kOrangeColor, bold: true,
                ),
                _DataCell(
                  '${days.fold(0, (s, d) => s + d.cornerNumber)}',
                  color: kPrimaryColor, bold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    child: Text(text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        textAlign: TextAlign.center),
  );
}

class _DataCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool   bold;
  const _DataCell(this.text, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
    child: Text(text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Theme.of(context).colorScheme.onSurface),
        textAlign: TextAlign.center),
  );
}
