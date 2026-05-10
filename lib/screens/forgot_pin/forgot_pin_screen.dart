// lib/screens/forgot_pin/forgot_pin_screen.dart

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

enum _ForgotStep { email, otp, newPin }

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  _ForgotStep _step = _ForgotStep.email;

  final _emailCtrl  = TextEditingController();
  final _otpCtrl    = TextEditingController();
  final _pin1Ctrl   = TextEditingController();
  final _pin2Ctrl   = TextEditingController();

  String  _firstPin = '';
  bool    _pinStep2 = false;
  String? _localError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AuthProvider auth) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    setState(() => _localError = null);
    final ok = await auth.sendForgotPinOtp(email);
    if (ok && mounted) setState(() => _step = _ForgotStep.otp);
  }

  Future<void> _verifyOtp(AuthProvider auth) async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _localError = 'Enter the 6-digit OTP from your email.');
      return;
    }
    setState(() => _localError = null);
    final ok = await auth.verifyForgotPinOtp(otp);
    if (ok && mounted) setState(() => _step = _ForgotStep.newPin);
  }

  Future<void> _onFirstPin(String pin) async {
    setState(() { _firstPin = pin; _pinStep2 = true; });
  }

  Future<void> _onConfirmPin(String pin, AuthProvider auth) async {
    if (pin == _firstPin) {
      await auth.resetPin(pin);
      if (mounted) {
        Navigator.pushReplacementNamed(context, kRouteHome);
      }
    } else {
      setState(() {
        _localError = 'PINs do not match. Try again.';
        _pinStep2   = false;
        _firstPin   = '';
        _pin1Ctrl.clear();
        _pin2Ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset PIN'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Step indicator
                _StepIndicator(current: _step),
                const SizedBox(height: 40),

                // Step content
                if (_step == _ForgotStep.email) _buildEmailStep(auth),
                if (_step == _ForgotStep.otp)   _buildOtpStep(auth),
                if (_step == _ForgotStep.newPin) _buildNewPinStep(auth),

                // Errors
                if ((_localError ?? auth.error) != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kRedColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _localError ?? auth.error!,
                      style: const TextStyle(color: kRedColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(AuthProvider auth) {
    return Column(
      children: [
        const Icon(Icons.email_outlined, size: 56, color: kPrimaryColor),
        const SizedBox(height: 20),
        Text('Enter your registered email',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('We\'ll send a 6-digit OTP to verify your identity.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 32),
        TextField(
          controller:   _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText:    'Email address',
            prefixIcon:   const Icon(Icons.alternate_email),
            border:       OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: auth.isLoading ? null : () => _sendOtp(auth),
            child: auth.isLoading
                ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                : const Text('Send OTP', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(AuthProvider auth) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56, color: kGreenColor),
        const SizedBox(height: 20),
        Text('Enter OTP',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Check your email for a 6-digit code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 32),
        TextField(
          controller:   _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength:    6,
          textAlign:    TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText:   'OTP',
            counterText: '',
            border:      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: auth.isLoading ? null : () => _verifyOtp(auth),
            child: auth.isLoading
                ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = _ForgotStep.email),
          child: const Text('Resend OTP'),
        ),
      ],
    );
  }

  Widget _buildNewPinStep(AuthProvider auth) {
    return Column(
      children: [
        const Icon(Icons.lock_reset_rounded, size: 56, color: kPrimaryColor),
        const SizedBox(height: 20),
        Text(_pinStep2 ? 'Confirm new PIN' : 'Set new PIN',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_pinStep2 ? 'Enter the same PIN once more.' : 'Choose a 4-digit PIN.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 40),
        if (_localError != null) ...[
          Text(_localError!, style: const TextStyle(color: kRedColor)),
          const SizedBox(height: 16),
        ],
        Pinput(
          controller:  _pinStep2 ? _pin2Ctrl : _pin1Ctrl,
          length:      kPinLength,
          obscureText: true,
          onCompleted: _pinStep2
              ? (pin) => _onConfirmPin(pin, auth)
              : _onFirstPin,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final _ForgotStep current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['Email', 'OTP', 'New PIN'];
    final idx   = _ForgotStep.values.indexOf(current);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final done   = i < idx;
        final active = i == idx;
        return Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:  active ? 32 : 24,
            height: active ? 32 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? kPrimaryColor : Colors.grey.withOpacity(0.3),
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text('${i + 1}',
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize:   active ? 14 : 12,
                      )),
            ),
          ),
          if (i < steps.length - 1)
            Container(
              width: 32, height: 2,
              color: i < idx ? kPrimaryColor : Colors.grey.withOpacity(0.3),
            ),
        ]);
      }),
    );
  }
}
