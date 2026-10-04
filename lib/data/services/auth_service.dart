import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Result type for auth operations.
class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult({required this.success, this.errorMessage});
  const AuthResult.ok() : success = true, errorMessage = null;
  const AuthResult.error(String message)
      : success = false,
        errorMessage = message;
}

/// Service wrapping Supabase Authentication operations.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Current Supabase user, or null if not authenticated.
  User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Sign up with email and password.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName.trim()} : null,
      );

      if (response.user == null) {
        return const AuthResult.error(
            'Sign up failed. Please check your details and try again.');
      }

      // Profile is created by the database trigger (handle_new_user).
      // We call _ensureProfile as a safety net in case the trigger didn't fire.
      await _ensureProfile(response.user!, displayName: displayName);

      return const AuthResult.ok();
    } on AuthException catch (e) {
      debugPrint('AuthService.signUp AuthException: ${e.statusCode} ${e.message}');
      return AuthResult.error(_friendlyMessage(e));
    } catch (e) {
      debugPrint('AuthService.signUp error: $e');
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  /// Sign in with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.error(_friendlyMessage(e));
    } catch (e) {
      debugPrint('AuthService.signIn error: $e');
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
    }
  }

  /// Send a password reset email.
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.error(_friendlyMessage(e));
    } catch (e) {
      debugPrint('AuthService.resetPassword error: $e');
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  /// Ensure a profile row exists for the user.
  /// Uses upsert so it's safe even if the DB trigger already created the row.
  Future<void> _ensureProfile(User user, {String? displayName}) async {
    try {
      final name = displayName?.trim() ??
          user.userMetadata?['display_name'] as String? ??
          '';
      await _client.from('profiles').upsert(
        {
          'id': user.id,
          'display_name': name,
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      // Non-fatal: the trigger may have already created the profile.
      debugPrint('AuthService._ensureProfile error: $e');
    }
  }

  /// Convert AuthException to user-friendly message.
  String _friendlyMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please check your email and confirm your account.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (msg.contains('weak password') || msg.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('database error')) {
      return 'Server configuration error. Please contact support or try again later.';
    }
    return e.message;
  }
}
