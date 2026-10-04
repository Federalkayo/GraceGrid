import '../services/local_storage_service.dart';
import '../services/mock_data_service.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/bible_reading.dart';
import '../../domain/models/daily_verse.dart';
import '../../domain/models/sermon.dart';
import '../../domain/models/live_stream.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/connect_item.dart';

class GraceGridRepository {
  final LocalStorageService _localStorageService;
  final MockDataService _mockDataService;

  GraceGridRepository({
    LocalStorageService? localStorageService,
    MockDataService? mockDataService,
  })  : _localStorageService = localStorageService ?? LocalStorageService(),
        _mockDataService = mockDataService ?? MockDataService();

  // User Profile
  Future<UserProfile> getUserProfile({bool forcedGuest = false}) async {
    final isSignedIn = forcedGuest ? false : await _localStorageService.getIsSignedIn();
    if (!isSignedIn) {
      return UserProfile.guest();
    }
    final name = await _localStorageService.getUserName();
    return UserProfile(
      id: 'usr_001',
      name: name,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      isSignedIn: true,
      unreadMessagesCount: 3,
      unreadNotificationsCount: 2,
    );
  }

  Future<void> toggleUserSignIn(bool isSignedIn) async {
    await _localStorageService.setSignedIn(isSignedIn);
  }

  // Bible Progress
  Future<BibleReadingProgress> getBibleProgress({bool hasHistory = true}) async {
    if (!hasHistory) {
      return BibleReadingProgress.empty();
    }
    final cached = await _localStorageService.getBibleReading();
    if (cached != null) return cached;

    final mock = await _mockDataService.fetchBibleReadingProgress(hasHistory: true);
    await _localStorageService.saveBibleReading(mock);
    return mock;
  }

  Future<void> updateBibleProgress(BibleReadingProgress progress) async {
    await _localStorageService.saveBibleReading(progress);
  }

  // Daily Verse
  Future<DailyVerse> getDailyVerse() async {
    final verse = await _mockDataService.fetchDailyVerse();
    final saved = await _localStorageService.isVerseSaved(verse.id);
    return verse.copyWith(isSaved: saved);
  }

  Future<bool> toggleSaveVerse(String verseId) async {
    await _localStorageService.toggleSaveVerse(verseId);
    return _localStorageService.isVerseSaved(verseId);
  }

  // Worship & Sermon
  Future<Sermon> getFeaturedSermon({bool isListening = true}) async {
    final cached = await _localStorageService.getSermonProgress();
    if (cached != null && isListening) return cached;

    final sermon = await _mockDataService.fetchFeaturedSermon(isListening: isListening);
    if (isListening) {
      await _localStorageService.saveSermonProgress(sermon);
    }
    return sermon;
  }

  Future<void> updateSermonPosition(Sermon sermon, int newPositionSeconds) async {
    final updated = sermon.copyWith(
      currentPositionSeconds: newPositionSeconds,
      isListening: true,
    );
    await _localStorageService.saveSermonProgress(updated);
  }

  // Live Streams
  Future<List<LiveStream>> getLiveStreams({bool isStreamActive = true}) async {
    return _mockDataService.fetchLiveStreams(isStreamActive: isStreamActive);
  }

  // Social Community Preview
  Future<List<CommunityPost>> getCommunityPreview() async {
    return _mockDataService.fetchCommunityPreview();
  }

  // Connect Summary
  Future<ConnectSummary> getConnectSummary({int unreadCount = 3}) async {
    return _mockDataService.fetchConnectSummary(unreadCount: unreadCount);
  }

  // Prayer Requests
  Future<List<PrayerRequest>> getPrayerRequests() async {
    return _mockDataService.fetchPrayerRequests();
  }
}
