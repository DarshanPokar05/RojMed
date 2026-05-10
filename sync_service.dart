// lib/core/constants.dart

import 'package:flutter/material.dart';

// ── Supabase ─────────────────────────────────────────────────
// Replace these with your actual Supabase project values
// from: Supabase Dashboard → Settings → API
const String kSupabaseUrl     = 'YOUR_SUPABASE_URL';
const String kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

// ── App Info ─────────────────────────────────────────────────
const String kAppName    = 'Roj Med';
const String kAppVersion = '1.0.0';

// ── Secure Storage Keys ──────────────────────────────────────
const String kKeyPin             = 'roj_med_pin';
const String kKeyEmail           = 'roj_med_email';
const String kKeyPinSetup        = 'roj_med_pin_setup_done';

// ── Shared Preferences Keys ──────────────────────────────────
const String kKeyLastSyncedAt    = 'last_synced_at';

// ── PIN Config ───────────────────────────────────────────────
const int kPinLength          = 4;
const int kMaxWrongAttempts   = 3;
const int kLockoutSeconds     = 30;

// ── Colors ───────────────────────────────────────────────────
const Color kPrimaryColor   = Color(0xFF1A5276);
const Color kAccentColor    = Color(0xFF2E86C1);
const Color kGreenColor     = Color(0xFF1E8449);
const Color kOrangeColor    = Color(0xFFD35400);
const Color kRedColor       = Color(0xFFC0392B);

// ── Supabase Table Names ─────────────────────────────────────
const String kTableDailyEntries = 'daily_entries';
const String kTableEntryItems   = 'entry_items';
const String kTableAppSettings  = 'app_settings';

// ── Entry Item Types ─────────────────────────────────────────
const String kTypeShop     = 'shop';
const String kTypePersonal = 'personal';

// ── Routes ───────────────────────────────────────────────────
const String kRoutePinLock       = '/';
const String kRouteForgotPin     = '/forgot-pin';
const String kRouteHome          = '/home';
const String kRouteEntryDetail   = '/entry-detail';
const String kRouteMonthlySummary = '/monthly-summary';
const String kRouteSettings      = '/settings';
