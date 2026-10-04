import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Data class for a Supabase profile row.
class ProfileData {
  final String id;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileData({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Service for Supabase profile CRUD operations.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const String _avatarBucket = 'avatars';

  SupabaseClient get _client => SupabaseService.client;

  /// Fetch the current user's profile.
  /// Returns null if not found or not authenticated.
  Future<ProfileData?> fetchMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return ProfileData.fromJson(data);
    } catch (e) {
      debugPrint('ProfileService.fetchMyProfile error: $e');
      return null;
    }
  }

  /// Fetch a profile by user ID (for viewing other users).
  Future<ProfileData?> fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileData.fromJson(data);
    } catch (e) {
      debugPrint('ProfileService.fetchProfile error: $e');
      return null;
    }
  }

  /// Update the current user's profile.
  /// Only updates fields that are provided (non-null).
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName.trim();
      if (bio != null) updates['bio'] = bio.trim();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return true;

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      // Also update Supabase auth metadata so the name/avatar stays in sync
      final metaUpdates = <String, dynamic>{};
      if (displayName != null) metaUpdates['display_name'] = displayName.trim();
      if (avatarUrl != null) metaUpdates['avatar_url'] = avatarUrl;
      if (metaUpdates.isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(data: metaUpdates),
        );
      }

      return true;
    } catch (e) {
      debugPrint('ProfileService.updateProfile error: $e');
      return false;
    }
  }

  /// Upload an avatar image to Supabase Storage and update the profile.
  /// Returns the public URL of the uploaded avatar, or null on failure.
  Future<String?> uploadAvatar(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final filePath = '${user.id}/avatar.$ext';

      // Upload (upsert) to the avatars bucket
      await _client.storage.from(_avatarBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get the public URL
      final publicUrl =
          _client.storage.from(_avatarBucket).getPublicUrl(filePath);

      // Add a cache-buster so the UI refreshes the image
      final urlWithBuster =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update profile with the new avatar URL
      await updateProfile(avatarUrl: urlWithBuster);

      return urlWithBuster;
    } catch (e) {
      debugPrint('ProfileService.uploadAvatar error: $e');
      return null;
    }
  }

  /// Search profiles by display name (for starting new conversations).
  Future<List<ProfileData>> searchProfiles(String query, {int limit = 20}) async {
    final user = _client.auth.currentUser;
    try {
      final response = await _client
          .from('profiles')
          .select()
          .ilike('display_name', '%$query%')
          .limit(limit);

      return (response as List)
          .map((json) => ProfileData.fromJson(json as Map<String, dynamic>))
          .where((p) => p.id != user?.id) // exclude self
          .toList();
    } catch (e) {
      debugPrint('ProfileService.searchProfiles error: $e');
      return [];
    }
  }
}
