// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/sync_service.dart';
import 'providers/auth_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/history_provider.dart';
import 'providers/summary_provider.dart';
import 'screens/pin_lock/pin_lock_screen.dart';
import 'screens/forgot_pin/forgot_pin_screen.dart';
import 'screens/calendar_view/calendar_screen.dart';
import 'screens/today_entry/today_entry_screen.dart';
import 'screens/monthly_summary/monthly_summary_screen.dart';
import 'screens/settings/settings_screen.dart';

class RojMedApp extends StatelessWidget {
  const RojMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => EntryProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
        ChangeNotifierProvider.value(value: SyncService.instance),
      ],
      child: MaterialApp(
        title:        kAppName,
        debugShowCheckedModeBanner: false,
        themeMode:    ThemeMode.system,
        theme:        _buildLightTheme(),
        darkTheme:    _buildDarkTheme(),
        initialRoute: kRoutePinLock,
        routes: {
          kRoutePinLock:        (_) => const PinLockScreen(),
          kRouteForgotPin:      (_) => const ForgotPinScreen(),
          kRouteHome:           (_) => const CalendarScreen(),
          kRouteMonthlySummary: (_) => const MonthlySummaryScreen(),
          kRouteSettings:       (_) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          // Entry detail — pass date argument
          if (settings.name == kRouteEntryDetail) {
            final date = settings.arguments as DateTime?;
            return MaterialPageRoute(
              builder: (_) => TodayEntryScreen(date: date),
            );
          }
          return null;
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor:   kPrimaryColor,
      brightness:  Brightness.light,
      primary:     kPrimaryColor,
      secondary:   kAccentColor,
    );
    return ThemeData(
      useMaterial3:  true,
      colorScheme:   scheme,
      fontFamily:    'Roboto',
      appBarTheme: AppBarTheme(
        elevation:        0,
        centerTitle:      false,
        backgroundColor:  scheme.surface,
        foregroundColor:  scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation:    0,
        color:        scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   scheme.surfaceContainerHighest.withOpacity(0.4),
        border:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: scheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor:   kPrimaryColor,
      brightness:  Brightness.dark,
      primary:     const Color(0xFF5DADE2),
      secondary:   kAccentColor,
    );
    return ThemeData(
      useMaterial3:  true,
      colorScheme:   scheme,
      fontFamily:    'Roboto',
      appBarTheme: AppBarTheme(
        elevation:        0,
        centerTitle:      false,
        backgroundColor:  scheme.surface,
        foregroundColor:  scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation:    0,
        color:        scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
        border:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: scheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5DADE2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
    );
  }
}
