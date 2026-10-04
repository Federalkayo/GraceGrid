import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'supabase_service.dart';

/// Singleton service managing the GetStream Chat client.
///
/// Security: The API key is a public client key (safe in Flutter).
/// The API secret is NEVER stored here — tokens are generated
/// server-side via a Supabase Edge Function.
class StreamChatService {
  StreamChatService._();
  static final StreamChatService instance = StreamChatService._();

  /// Public Stream API key (safe for client-side use).
  static const String _apiKey = 'ny4zvscgpxxz';

  late final StreamChatClient _client;
  bool _initialized = false;
  bool _userConnected = false;

  /// The shared StreamChatClient instance.
  StreamChatClient get client {
    _ensureInitialized();
    return _client;
  }

  bool get isUserConnected => _userConnected;

  /// Initialize the Stream client. Call once at app startup.
  void init() {
    if (_initialized) return;
    _client = StreamChatClient(
      _apiKey,
      logLevel: kDebugMode ? Level.INFO : Level.OFF,
    );
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) init();
  }

  /// Connect a user to Stream Chat after Supabase authentication.
  ///
  /// Fetches a secure token from the Supabase Edge Function.
  /// The Edge Function verifies the Supabase session and uses
  /// the Stream secret (server-side only) to mint the token.
  Future<void> connectUser({
    required String userId,
    required String displayName,
    String avatarUrl = '',
  }) async {
    _ensureInitialized();

    // Already connected as this user — skip
    if (_userConnected && _client.state.currentUser?.id == userId) {
      return;
    }

    // Disconnect previous user if switching accounts
    if (_userConnected) {
      await disconnectUser();
    }

    try {
      final token = await _fetchStreamToken(userId);

      await _client.connectUser(
        User(
          id: userId,
          name: displayName,
          image: avatarUrl.isNotEmpty ? avatarUrl : null,
        ),
        token,
      );
      _userConnected = true;
      debugPrint('StreamChatService: connected user $userId');
    } catch (e) {
      debugPrint('StreamChatService.connectUser error: $e');
      _userConnected = false;
      // Don't rethrow — Stream connection failure should not
      // block the rest of the app from working.
    }
  }

  /// Disconnect the current user from Stream Chat.
  Future<void> disconnectUser() async {
    if (!_initialized || !_userConnected) return;
    try {
      await _client.disconnectUser();
      debugPrint('StreamChatService: disconnected user');
    } catch (e) {
      debugPrint('StreamChatService.disconnectUser error: $e');
    }
    _userConnected = false;
  }

  /// Get or create a deterministic 1-to-1 DM channel.
  ///
  /// The channel ID is derived from sorted user IDs (stripped of hyphens)
  /// so the same two users always resolve to the same conversation.
  Future<Channel> getOrCreateDMChannel(String otherUserId) async {
    _ensureInitialized();
    if (!_userConnected) {
      throw StateError('Must connect user before opening a channel');
    }

    final currentUserId = _client.state.currentUser!.id;
    final cleanCurrent = currentUserId.replaceAll('-', '');
    final cleanOther = otherUserId.replaceAll('-', '');
    final ids = [cleanCurrent, cleanOther]..sort();
    final channelId = '${ids[0]}${ids[1]}';

    final channel = _client.channel(
      'messaging',
      id: channelId,
      extraData: const {},
    );

    await channel.watch();

    // Ensure both users are members
    try {
      await channel.addMembers([currentUserId, otherUserId]);
    } catch (_) {
      // Members may already exist — safe to ignore
    }

    return channel;
  }

  /// Fetch a Stream user token from the Supabase Edge Function.
  Future<String> _fetchStreamToken(String userId) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'get-stream-token',
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('token') && data['token'] is String) {
          return data['token'] as String;
        }
      }

      throw Exception(
        'Stream token request failed (status ${response.status}: ${response.data})',
      );
    } catch (e) {
      debugPrint('StreamChatService._fetchStreamToken error: $e');
      rethrow;
    }
  }
}
