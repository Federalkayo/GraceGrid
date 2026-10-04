import 'package:flutter/material.dart';
import '../features/auth/auth_notifier.dart';
import '../features/auth/auth_screen.dart';

/// Shows an auth prompt if the user is not authenticated.
///
/// Returns `true` if the user is authenticated (or just signed in),
/// `false` if they dismissed the auth screen.
///
/// Usage:
/// ```dart
/// if (!await requireAuth(context, authNotifier)) return;
/// // proceed with account-required action
/// ```
Future<bool> requireAuth(BuildContext context, AuthNotifier authNotifier) async {
  if (authNotifier.isAuthenticated) return true;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AuthScreen(authNotifier: authNotifier),
    ),
  );

  // After returning from auth screen, check if now authenticated
  return authNotifier.isAuthenticated;
}
