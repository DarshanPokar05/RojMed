// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../data/remote/supabase_service.dart';

enum AuthState { locked, unlocked, settingPin }

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  AuthState _state       = AuthState.locked;
  int       _wrongCount  = 0;
  bool      _isLockedOut = false;
  int       _lockoutSecsRemaining = 0;
  bool      _isPinSet    = false;
  bool      _isLoading   = false;
  String?   _error;

  AuthState get state               => _state;
  bool      get isUnlocked          => _state == AuthState.unlocked;
  bool      get isLockedOut         => _isLockedOut;
  int       get lockoutSecsRemaining => _lockoutSecsRemaining;
  int       get wrongCount          => _wrongCount;
  bool      get isPinSet            => _isPinSet;
  bool      get isLoading           => _isLoading;
  String?   get error               => _error;

  // ── Initialise ────────────────────────────────────────────

  Future<void> init() async {
    final pinSetup = await _storage.read(key: kKeyPinSetup);
    _isPinSet = pinSetup == 'true';
    if (!_isPinSet) _state = AuthState.settingPin;
    notifyListeners();
  }

  // ── Verify PIN ────────────────────────────────────────────

  Future<bool> verifyPin(String enteredPin) async {
    if (_isLockedOut) return false;
    _clearError();

    final storedPin = await _storage.read(key: kKeyPin);
    if (enteredPin == storedPin) {
      _wrongCount = 0;
      _state = AuthState.unlocked;
      notifyListeners();
      return true;
    }

    _wrongCount++;
    if (_wrongCount >= kMaxWrongAttempts) {
      _startLockout();
    } else {
      _error = 'Incorrect PIN (${kMaxWrongAttempts - _wrongCount} attempts left)';
      notifyListeners();
    }
    return false;
  }

  // ── Set PIN ───────────────────────────────────────────────

  Future<void> setPin(String pin) async {
    await _storage.write(key: kKeyPin, value: pin);
    await _storage.write(key: kKeyPinSetup, value: 'true');
    _isPinSet = true;
    _state    = AuthState.unlocked;
    notifyListeners();
  }

  // ── Change PIN (from settings — verify old first) ─────────

  Future<bool> changePin(String oldPin, String newPin) async {
    final storedPin = await _storage.read(key: kKeyPin);
    if (oldPin != storedPin) {
      _error = 'Current PIN is incorrect';
      notifyListeners();
      return false;
    }
    await setPin(newPin);
    return true;
  }

  // ── Forgot PIN — send OTP ─────────────────────────────────

  Future<bool> sendForgotPinOtp(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await SupabaseService.instance.sendOtp(email);
      // Save email for OTP verification step
      await _storage.write(key: kKeyEmail, value: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to send OTP. Check email and try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ── Forgot PIN — verify OTP ───────────────────────────────

  Future<bool> verifyForgotPinOtp(String otp) async {
    _setLoading(true);
    _clearError();
    try {
      final email = await _storage.read(key: kKeyEmail) ?? '';
      final ok = await SupabaseService.instance.verifyOtp(email, otp);
      _setLoading(false);
      if (!ok) {
        _error = 'Invalid or expired OTP. Please try again.';
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = 'Verification failed. Try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ── Reset PIN after OTP success ───────────────────────────

  Future<void> resetPin(String newPin) async {
    await setPin(newPin);
    _wrongCount = 0;
  }

  // ── Lock (on app background) ──────────────────────────────

  void lock() {
    _state = AuthState.locked;
    notifyListeners();
  }

  // ── Lockout timer ─────────────────────────────────────────

  void _startLockout() {
    _isLockedOut = true;
    _lockoutSecsRemaining = kLockoutSeconds;
    notifyListeners();
    _tickLockout();
  }

  Future<void> _tickLockout() async {
    while (_lockoutSecsRemaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      _lockoutSecsRemaining--;
      notifyListeners();
    }
    _isLockedOut = false;
    _wrongCount  = 0;
    notifyListeners();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _clearError()       { _error = null; }
}
