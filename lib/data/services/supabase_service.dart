import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for Supabase initialization and client access.
class SupabaseService {
  SupabaseService._();

  static const String _supabaseUrl = 'https://lwxriovnrhgobsmfnqdm.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3eHJpb3Zucmhnb2JzbWZucWRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5NDk2NzcsImV4cCI6MjEwNjUyNTY3N30.mr4D4orkci-7tINb1uUMQolnFju6MEnl8NkUXuIACQU';

  static bool _initialized = false;

  /// Initialize Supabase. Call once in main().
  static Future<void> init() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
    _initialized = true;
  }

  /// The Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}
