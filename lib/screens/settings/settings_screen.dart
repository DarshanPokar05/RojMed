// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatter.dart';
import '../../core/sync_service.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  String _email  = '';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final e = await _storage.read(key: kKeyEmail) ?? '';
    if (mounted) setState(() => _email = e);
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final sync   = context.watch<SyncService>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── App Info ──────────────────────────────────────
          _SettingsSection(
            title: 'App',
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 22),
                ),
                title: const Text('Roj Med',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Version $kAppVersion'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Security ──────────────────────────────────────
          _SettingsSection(
            title: 'Security',
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined, color: kPrimaryColor),
                title: const Text('Registered Email'),
                subtitle: Text(_email.isEmpty ? 'Not set' : _email,
                    style: TextStyle(
                        color: _email.isEmpty
                            ? kOrangeColor
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showChangeEmailSheet(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: kPrimaryColor),
                title: const Text('Change PIN'),
                subtitle: const Text('Update your 4-digit PIN'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showChangePinSheet(context, auth),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Sync ──────────────────────────────────────────
          _SettingsSection(
            title: 'Sync',
            children: [
              ListTile(
                leading: Icon(
                  sync.status == SyncStatus.synced  ? Icons.cloud_done_rounded :
                  sync.status == SyncStatus.syncing ? Icons.cloud_sync_rounded  :
                  sync.status == SyncStatus.offline ? Icons.cloud_off_rounded   :
                  Icons.cloud_upload_rounded,
                  color: sync.status == SyncStatus.synced  ? kGreenColor  :
                         sync.status == SyncStatus.offline ? Colors.grey   :
                         kOrangeColor,
                ),
                title: Text(
                  sync.status == SyncStatus.synced  ? 'Synced'         :
                  sync.status == SyncStatus.syncing ? 'Syncing...'     :
                  sync.status == SyncStatus.offline ? 'Offline'        :
                  sync.status == SyncStatus.error   ? 'Sync Error'     :
                  'Idle',
                ),
                subtitle: Text(RojMedFormatter.lastSynced(sync.lastSync)),
                trailing: sync.isSyncing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: () => SyncService.instance.syncAll(),
                        child: const Text('Sync Now'),
                      ),
              ),
              if (sync.errorMsg != null) ...[
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.error_outline, color: kRedColor),
                  title: Text('Last error',
                      style: const TextStyle(color: kRedColor, fontSize: 13)),
                  subtitle: Text(sync.errorMsg!,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Danger Zone ───────────────────────────────────
          _SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: kRedColor),
                title: const Text('Lock App',
                    style: TextStyle(color: kRedColor)),
                onTap: () {
                  context.read<AuthProvider>().lock();
                  Navigator.pushNamedAndRemoveUntil(
                      context, kRoutePinLock, (_) => false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Change Email Bottom Sheet ─────────────────────────────

  void _showChangeEmailSheet(BuildContext context) {
    final ctrl = TextEditingController(text: _email);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Email',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('This email is used to reset your PIN via OTP.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller:   ctrl,
              keyboardType: TextInputType.emailAddress,
              autofocus:    true,
              decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final email = ctrl.text.trim();
                  if (email.isEmpty || !email.contains('@')) return;
                  await _storage.write(key: kKeyEmail, value: email);
                  setState(() => _email = email);
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change PIN Bottom Sheet ───────────────────────────────

  void _showChangePinSheet(BuildContext context, AuthProvider auth) {
    final oldCtrl  = TextEditingController();
    final new1Ctrl = TextEditingController();
    final new2Ctrl = TextEditingController();
    int step = 0; // 0=old, 1=new, 2=confirm
    String firstNew = '';
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step == 0 ? 'Enter Current PIN' :
                step == 1 ? 'Enter New PIN'     : 'Confirm New PIN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 24),
              if (error != null) ...[
                Text(error!, style: const TextStyle(color: kRedColor, fontSize: 13)),
                const SizedBox(height: 16),
              ],
              Pinput(
                controller: step == 0 ? oldCtrl : step == 1 ? new1Ctrl : new2Ctrl,
                length: kPinLength,
                obscureText: true,
                autofocus:   true,
                onCompleted: (pin) async {
                  if (step == 0) {
                    final stored = await _storage.read(key: kKeyPin);
                    if (pin == stored) {
                      setModalState(() { step = 1; error = null; oldCtrl.clear(); });
                    } else {
                      setModalState(() { error = 'Incorrect PIN'; oldCtrl.clear(); });
                    }
                  } else if (step == 1) {
                    firstNew = pin;
                    setModalState(() { step = 2; new1Ctrl.clear(); });
                  } else {
                    if (pin == firstNew) {
                      await auth.setPin(pin);
                      Navigator.pop(ctx2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN updated successfully'),
                          backgroundColor: kGreenColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      setModalState(() {
                        error = 'PINs don\'t match. Start over.';
                        step = 0; firstNew = '';
                        oldCtrl.clear(); new1Ctrl.clear(); new2Ctrl.clear();
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String       title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 1.2)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
