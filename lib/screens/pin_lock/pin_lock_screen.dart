// lib/screens/pin_lock/pin_lock_screen.dart

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _onPinCompleted(String pin, AuthProvider auth) async {
    final ok = await auth.verifyPin(pin);
    if (ok) {
      if (mounted) Navigator.pushReplacementNamed(context, kRouteHome);
    } else {
      _shake();
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If PIN not set yet, go to setup
    if (auth.state == AuthState.settingPin) {
      return const _PinSetupScreen();
    }

    final defaultTheme = PinTheme(
      width:  56,
      height: 60,
      decoration: BoxDecoration(
        color:        isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.transparent),
      ),
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
    );

    final focusedTheme = defaultTheme.copyDecorationWith(
      decoration: BoxDecoration(
        color:        isDark ? Colors.white12 : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: kPrimaryColor, width: 2),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // App icon / logo
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color:        kPrimaryColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color:       kPrimaryColor.withOpacity(0.35),
                        blurRadius:  20,
                        offset:      const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 44),
                ),

                const SizedBox(height: 24),
                Text('Roj Med',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const SizedBox(height: 8),
                Text('Enter your PIN to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withOpacity(0.6))),

                const SizedBox(height: 48),

                // Lockout message
                if (auth.isLockedOut) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color:        kRedColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_clock, color: kRedColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Too many attempts. Wait ${auth.lockoutSecsRemaining}s',
                          style: const TextStyle(color: kRedColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error message
                if (auth.error != null && !auth.isLockedOut) ...[
                  Text(auth.error!,
                      style: const TextStyle(color: kRedColor, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],

                // PIN dots — shake on wrong
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (ctx, child) => Transform.translate(
                    offset: Offset(
                      _shakeCtrl.isAnimating
                          ? ((_shakeCtrl.value * 4).round().isEven ? 1 : -1) * _shakeAnim.value
                          : 0,
                      0,
                    ),
                    child: child,
                  ),
                  child: Pinput(
                    controller:    _pinController,
                    length:        kPinLength,
                    obscureText:   true,
                    enabled:       !auth.isLockedOut,
                    defaultPinTheme: defaultTheme,
                    focusedPinTheme: focusedTheme,
                    onCompleted: (pin) => _onPinCompleted(pin, auth),
                  ),
                ),

                const SizedBox(height: 32),

                // Forgot PIN
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, kRouteForgotPin),
                  child: Text('Forgot PIN?',
                      style: TextStyle(color: kAccentColor, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PIN Setup (first-time) ────────────────────────────────────

class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen();

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  final _pin1Ctrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  bool _step2     = false;
  String _firstPin = '';
  String? _mismatch;

  void _onFirstPin(String pin) {
    setState(() { _firstPin = pin; _step2 = true; });
  }

  Future<void> _onConfirmPin(String pin, AuthProvider auth) async {
    if (pin == _firstPin) {
      await auth.setPin(pin);
      if (mounted) Navigator.pushReplacementNamed(context, kRouteHome);
    } else {
      setState(() {
        _mismatch = 'PINs do not match. Try again.';
        _step2    = false;
        _firstPin = '';
        _pin1Ctrl.clear();
        _pin2Ctrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 64, color: kPrimaryColor),
                const SizedBox(height: 24),
                Text(
                  _step2 ? 'Confirm your PIN' : 'Set a 4-digit PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _step2 ? 'Enter the same PIN again' : 'You\'ll use this to unlock the app',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 40),
                if (_mismatch != null) ...[
                  Text(_mismatch!,
                      style: const TextStyle(color: kRedColor, fontSize: 13)),
                  const SizedBox(height: 16),
                ],
                Pinput(
                  controller:  _step2 ? _pin2Ctrl : _pin1Ctrl,
                  length:      kPinLength,
                  obscureText: true,
                  onCompleted: _step2
                      ? (pin) => _onConfirmPin(pin, auth)
                      : _onFirstPin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
