import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/stream_chat_service.dart';
import '../../../domain/models/user_profile.dart';

/// App-wide notifier for authentication state.
///
/// Widgets can listen to this to reactively update when the user signs in/out.
class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final ProfileService _profileService = ProfileService.instance;
  StreamSubscription<AuthState>? _sub;

  UserProfile _userProfile = UserProfile.guest();
  bool _loading = true;

  AuthNotifier() {
    _init();
  }

  UserProfile get userProfile => _userProfile;
  bool get isAuthenticated => _userProfile.isSignedIn;
  bool get isLoading => _loading;
  String? get userId => _authService.currentUser?.id;

  void _init() {
    // Set initial state from existing session
    _syncProfile();

    // Listen for auth state changes
    _sub = _authService.onAuthStateChange.listen((authState) {
      _syncProfile();
    });
  }

  /// Sync the local UserProfile from auth state + Supabase profiles table.
  Future<void> _syncProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Immediately set from auth metadata (fast, no network)
      final metaName = user.userMetadata?['display_name'] as String? ??
          user.email?.split('@').first ??
          'User';
      _userProfile = UserProfile(
        id: user.id,
        name: metaName,
        email: user.email ?? '',
        avatarUrl: user.userMetadata?['avatar_url'] as String? ?? '',
        bio: '',
        isSignedIn: true,
      );
      _loading = false;
      notifyListeners();

      // Connect to Stream Chat in background
      StreamChatService.instance.connectUser(
        userId: user.id,
        displayName: metaName,
        avatarUrl: _userProfile.avatarUrl,
      );

      // Then fetch the full profile from Supabase (may have bio, updated name)
      final profile = await _profileService.fetchMyProfile();
      if (profile != null) {
        _userProfile = _userProfile.copyWith(
          name: profile.displayName.isNotEmpty ? profile.displayName : null,
          avatarUrl: profile.avatarUrl.isNotEmpty ? profile.avatarUrl : null,
          bio: profile.bio,
        );
        notifyListeners();

        // Update Stream user if profile name or avatar changed
        StreamChatService.instance.connectUser(
          userId: user.id,
          displayName: _userProfile.name,
          avatarUrl: _userProfile.avatarUrl,
        );
      }
    } else {
      _userProfile = UserProfile.guest();
      _loading = false;
      notifyListeners();

      // Disconnect Stream user on sign out
      StreamChatService.instance.disconnectUser();
    }
  }

  /// Update the local profile after an edit, without re-fetching.
  void updateProfile({String? displayName, String? avatarUrl, String? bio}) {
    if (!isAuthenticated) return;
    _userProfile = _userProfile.copyWith(
      name: displayName ?? _userProfile.name,
      avatarUrl: avatarUrl ?? _userProfile.avatarUrl,
      bio: bio ?? _userProfile.bio,
    );
    notifyListeners();
  }

  /// Refresh profile from Supabase.
  Future<void> refreshProfile() async {
    await _syncProfile();
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _authService.signUp(
        email: email, password: password, displayName: displayName);
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return _authService.signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<AuthResult> resetPassword(String email) async {
    return _authService.resetPassword(email);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

