// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/sync_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase
  await Supabase.initialize(
    url:     kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  // Start connectivity listener for auto-sync
  SyncService.instance.startListening();

  // Initial sync attempt on launch
  SyncService.instance.syncAll();

  runApp(const RojMedApp());
}
