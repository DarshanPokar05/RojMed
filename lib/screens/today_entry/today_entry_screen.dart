// lib/screens/today_entry/today_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatter.dart';
import '../../core/sync_service.dart';
import '../../providers/entry_provider.dart';
import '../../providers/history_provider.dart';

class TodayEntryScreen extends StatefulWidget {
  final DateTime? date; // null = today
  const TodayEntryScreen({super.key, this.date});

  @override
  State<TodayEntryScreen> createState() => _TodayEntryScreenState();
}

class _TodayEntryScreenState extends State<TodayEntryScreen> {
  // Controllers mirror provider's EntryLines
  final List<TextEditingController> _shopLabelCtrls  = [];
  final List<TextEditingController> _shopAmtCtrls    = [];
  final List<TextEditingController> _persLabelCtrls  = [];
  final List<TextEditingController> _persAmtCtrls    = [];

  late TextEditingController _openingCtrl;
  late TextEditingController _collectionCtrl;
  bool _controllersReady = false;

  @override
  void initState() {
    super.initState();
    _openingCtrl    = TextEditingController();
    _collectionCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prov = context.read<EntryProvider>();
    await prov.loadEntry(widget.date ?? DateTime.now());
    if (!mounted) return;
    _syncControllersFromProvider(prov);
    setState(() => _controllersReady = true);
  }

  void _syncControllersFromProvider(EntryProvider prov) {
    _openingCtrl.text    = prov.openingBalance    == 0 ? '' : prov.openingBalance.toStringAsFixed(2);
    _collectionCtrl.text = prov.dailyCollection   == 0 ? '' : prov.dailyCollection.toStringAsFixed(2);

    _syncLineControllers(prov.shopLines,     _shopLabelCtrls,  _shopAmtCtrls);
    _syncLineControllers(prov.personalLines, _persLabelCtrls,  _persAmtCtrls);
  }

  void _syncLineControllers(
      List<EntryLine> lines,
      List<TextEditingController> labelCtrls,
      List<TextEditingController> amtCtrls) {
    // Dispose extra
    while (labelCtrls.length > lines.length) {
      labelCtrls.removeLast().dispose();
      amtCtrls.removeLast().dispose();
    }
    // Add missing
    while (labelCtrls.length < lines.length) {
      labelCtrls.add(TextEditingController());
      amtCtrls.add(TextEditingController());
    }
    // Set values
    for (int i = 0; i < lines.length; i++) {
      if (labelCtrls[i].text != lines[i].label) labelCtrls[i].text = lines[i].label;
      final amtStr = lines[i].amount == 0 ? '' : lines[i].amount.toStringAsFixed(2);
      if (amtCtrls[i].text != amtStr) amtCtrls[i].text = amtStr;
    }
  }

  @override
  void dispose() {
    _openingCtrl.dispose();
    _collectionCtrl.dispose();
    for (final c in _shopLabelCtrls)  c.dispose();
    for (final c in _shopAmtCtrls)    c.dispose();
    for (final c in _persLabelCtrls)  c.dispose();
    for (final c in _persAmtCtrls)    c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prov = context.read<EntryProvider>();
    final ok   = await prov.saveEntry();
    if (!mounted) return;
    if (ok) {
      context.read<HistoryProvider>().invalidateCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:  Text('Entry saved successfully'),
          backgroundColor: kGreenColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:     Text(prov.error ?? 'Failed to save'),
          backgroundColor: kRedColor,
          behavior:    SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<EntryProvider>();
    final sync   = context.watch<SyncService>();
    final isToday = widget.date == null ||
        _isSameDay(widget.date!, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isToday ? 'Today\'s Entry' : 'Entry',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(RojMedFormatter.dateDisplay(widget.date ?? DateTime.now()),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // Sync status
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              sync.status == SyncStatus.synced  ? Icons.cloud_done_rounded :
              sync.status == SyncStatus.syncing ? Icons.cloud_sync_rounded  :
              sync.status == SyncStatus.offline ? Icons.cloud_off_rounded   :
              Icons.cloud_upload_rounded,
              color: sync.status == SyncStatus.synced  ? kGreenColor  :
                     sync.status == SyncStatus.offline ? Colors.grey   :
                     kOrangeColor,
              size: 22,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => Navigator.pushNamed(context, kRouteHome),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, kRouteSettings),
          ),
        ],
      ),
      body: prov.isLoading || !_controllersReady
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(prov),
      bottomNavigationBar: _buildBottomBar(prov),
    );
  }

  Widget _buildBody(EntryProvider prov) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Corner Number badge ───────────────────────────────
        if (prov.cornerNumber > 0)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:        kPrimaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${prov.cornerNumber}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // ── Opening Balance ───────────────────────────────────
        _SectionCard(
          title: 'Opening Balance',
          icon:  Icons.account_balance_outlined,
          color: kPrimaryColor,
          child: _AmountField(
            controller: _openingCtrl,
            label:      'Opening Balance (₹)',
            onChanged:  (v) => prov.setOpeningBalance(RojMedFormatter.parseAmount(v)),
          ),
        ),

        const SizedBox(height: 12),

        // ── Shop Items ────────────────────────────────────────
        _SectionCard(
          title: 'Shop Items',
          icon:  Icons.store_outlined,
          color: kAccentColor,
          trailing: Text(
            RojMedFormatter.currencyCompact(prov.shopTotal),
            style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold),
          ),
          child: Column(
            children: [
              ...List.generate(prov.shopLines.length, (i) => _ItemRow(
                index:      i,
                labelCtrl:  _shopLabelCtrls.length > i ? _shopLabelCtrls[i] : TextEditingController(),
                amountCtrl: _shopAmtCtrls.length  > i ? _shopAmtCtrls[i]   : TextEditingController(),
                onLabelChanged:  (v) => prov.updateShopLine(i, label: v),
                onAmountChanged: (v) => prov.updateShopLine(i, amount: RojMedFormatter.parseAmount(v)),
                onRemove: prov.shopLines.length > 1 ? () {
                  _shopLabelCtrls[i].dispose();
                  _shopAmtCtrls[i].dispose();
                  _shopLabelCtrls.removeAt(i);
                  _shopAmtCtrls.removeAt(i);
                  prov.removeShopLine(i);
                } : null,
              )),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _shopLabelCtrls.add(TextEditingController());
                  _shopAmtCtrls.add(TextEditingController());
                  prov.addShopLine();
                },
                icon:  const Icon(Icons.add_circle_outline),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Daily Collection (manual) ─────────────────────────
        _SectionCard(
          title: 'Daily Collection',
          icon:  Icons.payments_outlined,
          color: kGreenColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your cash collection for today',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 8),
              _AmountField(
                controller: _collectionCtrl,
                label:      'Daily Collection (₹)',
                onChanged:  (v) => prov.setDailyCollection(RojMedFormatter.parseAmount(v)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Personal Spends ───────────────────────────────────
        _SectionCard(
          title: 'Personal Spends',
          icon:  Icons.person_outline_rounded,
          color: kOrangeColor,
          trailing: Text(
            RojMedFormatter.currencyCompact(prov.personalTotal),
            style: const TextStyle(color: kOrangeColor, fontWeight: FontWeight.bold),
          ),
          child: Column(
            children: [
              ...List.generate(prov.personalLines.length, (i) => _ItemRow(
                index:      i,
                labelCtrl:  _persLabelCtrls.length > i ? _persLabelCtrls[i] : TextEditingController(),
                amountCtrl: _persAmtCtrls.length   > i ? _persAmtCtrls[i]   : TextEditingController(),
                onLabelChanged:  (v) => prov.updatePersonalLine(i, label: v),
                onAmountChanged: (v) => prov.updatePersonalLine(i, amount: RojMedFormatter.parseAmount(v)),
                onRemove: prov.personalLines.length > 1 ? () {
                  _persLabelCtrls[i].dispose();
                  _persAmtCtrls[i].dispose();
                  _persLabelCtrls.removeAt(i);
                  _persAmtCtrls.removeAt(i);
                  prov.removePersonalLine(i);
                } : null,
              )),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _persLabelCtrls.add(TextEditingController());
                  _persAmtCtrls.add(TextEditingController());
                  prov.addPersonalLine();
                },
                icon:  const Icon(Icons.add_circle_outline),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Calculated Summary Card ───────────────────────────
        _SummaryCard(prov: prov),

        const SizedBox(height: 100), // bottom padding for FAB
      ],
    );
  }

  Widget _buildBottomBar(EntryProvider prov) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (prov.hasExistingEntry)
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(prov),
                icon:  const Icon(Icons.delete_outline, color: kRedColor),
                label: const Text('Delete', style: TextStyle(color: kRedColor)),
                style: OutlinedButton.styleFrom(
                  side:   const BorderSide(color: kRedColor),
                  shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            if (prov.hasExistingEntry) const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: prov.isSaving ? null : _save,
                icon:  prov.isSaving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(prov.isSaving ? 'Saving...' : 'Save Entry',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(EntryProvider prov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Delete Entry?'),
        content: const Text('This will permanently delete this day\'s entry.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: kRedColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await prov.deleteEntry();
      if (mounted) Navigator.pop(context);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Reusable widgets ──────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String  title;
  final IconData icon;
  final Color   color;
  final Widget  child;
  final Widget? trailing;
  const _SectionCard({
    required this.title, required this.icon,
    required this.color, required this.child, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  const _AmountField({required this.controller, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText:   label,
        prefixText:  '₹ ',
        border:      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense:     true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final TextEditingController labelCtrl;
  final TextEditingController amountCtrl;
  final ValueChanged<String>  onLabelChanged;
  final ValueChanged<String>  onAmountChanged;
  final VoidCallback?         onRemove;
  const _ItemRow({
    required this.index, required this.labelCtrl, required this.amountCtrl,
    required this.onLabelChanged, required this.onAmountChanged, this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                hintText:       'Description',
                border:         OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense:        true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: onLabelChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller:  amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                hintText:       'Amount',
                prefixText:     '₹ ',
                border:         OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense:        true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              onChanged: onAmountChanged,
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, color: kRedColor),
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final EntryProvider prov;
  const _SummaryCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kAccentColor],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      kPrimaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Summary',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Corner: ${prov.cornerNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow('Opening Balance',   RojMedFormatter.currency(prov.openingBalance)),
          _SummaryRow('+ Daily Collection', RojMedFormatter.currency(prov.dailyCollection)),
          _SummaryRow('- Shop Total',       RojMedFormatter.currency(prov.shopTotal)),
          _SummaryRow('- Personal Total',   RojMedFormatter.currency(prov.personalTotal)),
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Closing Balance',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                RojMedFormatter.currency(prov.closingBalance),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value,  style: const TextStyle(color: Colors.white,   fontSize: 13)),
        ],
      ),
    );
  }
}
