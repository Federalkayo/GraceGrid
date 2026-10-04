import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/prayer.dart';
import 'supabase_service.dart';

/// Service for prayer requests, praying actions, via Supabase.
class PrayerService {
  PrayerService._();
  static final PrayerService instance = PrayerService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Fetch the prayer wall (all requests, newest first).
  Future<List<PrayerRequest>> fetchPrayerWall({int limit = 30}) async {
    try {
      final userId = _client.auth.currentUser?.id;

      final data = await _client
          .from('prayer_requests')
          .select('*, profiles!prayer_requests_profiles_fkey(display_name, avatar_url)')
          .order('created_at', ascending: false)
          .limit(limit);

      // Check which prayers the current user has prayed for
      Set<String> prayedIds = {};
      if (userId != null && data.isNotEmpty) {
        final ids = data.map((r) => r['id'] as String).toList();
        final prays = await _client
            .from('prayer_prays')
            .select('prayer_id')
            .eq('user_id', userId)
            .inFilter('prayer_id', ids);
        prayedIds = prays.map((r) => r['prayer_id'] as String).toSet();
      }

      return data.map((json) {
        final pId = json['id'] as String;
        return PrayerRequest.fromJson(json, isPrayedByMe: prayedIds.contains(pId));
      }).toList();
    } catch (e) {
      debugPrint('PrayerService.fetchPrayerWall error: $e');
      return [];
    }
  }

  /// Fetch only the current user's prayer requests.
  Future<List<PrayerRequest>> fetchMyRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _client
          .from('prayer_requests')
          .select('*, profiles!prayer_requests_profiles_fkey(display_name, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => PrayerRequest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('PrayerService.fetchMyRequests error: $e');
      return [];
    }
  }

  /// Submit a new prayer request. Returns the created request or null.
  Future<PrayerRequest?> createRequest({
    required String title,
    required String requestText,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('prayer_requests')
          .insert({
            'user_id': user.id,
            'title': title.trim(),
            'request_text': requestText.trim(),
          })
          .select('*, profiles!prayer_requests_profiles_fkey(display_name, avatar_url)')
          .single();

      return PrayerRequest.fromJson(data);
    } catch (e) {
      debugPrint('PrayerService.createRequest error: $e');
      return null;
    }
  }

  /// Delete a prayer request (own only — RLS enforced).
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _client.from('prayer_requests').delete().eq('id', requestId);
      return true;
    } catch (e) {
      debugPrint('PrayerService.deleteRequest error: $e');
      return false;
    }
  }

  /// Toggle "I'm praying" on a request. Returns new count or null.
  Future<int?> togglePray(String requestId, {required bool currentlyPrayed}) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      if (currentlyPrayed) {
        await _client
            .from('prayer_prays')
            .delete()
            .eq('prayer_id', requestId)
            .eq('user_id', user.id);
        await _client.rpc('decrement_praying_count', params: {'p_prayer_id': requestId});
      } else {
        await _client
            .from('prayer_prays')
            .insert({'prayer_id': requestId, 'user_id': user.id});
        await _client.rpc('increment_praying_count', params: {'p_prayer_id': requestId});
      }

      final row = await _client
          .from('prayer_requests')
          .select('praying_count')
          .eq('id', requestId)
          .single();
      return row['praying_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('PrayerService.togglePray error: $e');
      return null;
    }
  }

  /// Mark a prayer request as answered (own only).
  Future<bool> markAnswered(String requestId) async {
    try {
      await _client
          .from('prayer_requests')
          .update({'is_answered': true})
          .eq('id', requestId);
      return true;
    } catch (e) {
      debugPrint('PrayerService.markAnswered error: $e');
      return false;
    }
  }
}
