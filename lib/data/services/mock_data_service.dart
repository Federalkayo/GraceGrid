import '../../domain/models/bible_reading.dart';
import '../../domain/models/daily_verse.dart';
import '../../domain/models/sermon.dart';
import '../../domain/models/live_stream.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/connect_item.dart';

class MockDataService {
  // Simulated asynchronous service methods for independent section loading

  Future<DailyVerse> fetchDailyVerse() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const DailyVerse(
      id: 'dv_101',
      verseText: 'Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
      reference: 'Proverbs 3:5-6',
      translation: 'KJV',
      category: 'Trust & Faith',
      dateString: 'October 1, 2026',
      isSaved: false,
      shareCount: 384,
    );
  }

  Future<BibleReadingProgress> fetchBibleReadingProgress({bool hasHistory = true}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!hasHistory) {
      return BibleReadingProgress.empty();
    }
    return BibleReadingProgress(
      book: 'John',
      chapter: 3,
      verse: 16,
      translation: 'KJV',
      progressPercentage: 0.68,
      snippetText: 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
      lastReadAt: DateTime.now().subtract(const Duration(hours: 2)),
      hasReadingHistory: true,
      activePlanName: '30 Days with the Gospels',
      activePlanDay: 12,
      activePlanTotalDays: 30,
    );
  }

  Future<Sermon> fetchFeaturedSermon({bool isListening = true}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Sermon(
      id: 'sermon_201',
      title: 'Walking in Grace & Unshakable Purpose',
      speaker: 'Pastor Michael Carter',
      seriesName: 'Renewed Strength Series',
      durationFormatted: '38:15',
      totalDurationSeconds: 2295,
      currentPositionSeconds: isListening ? 1140 : 0,
      audioUrl: 'https://example.com/audio/sermon.mp3',
      thumbnailUrl: 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3',
      date: 'Sunday Worship Service',
      isFeatured: true,
      isListening: isListening,
      summaryNotes: 'Key takeaway: True grace empowers us not just to survive trial, but to reflect Christ in every daily interaction.',
    );
  }

  Future<List<LiveStream>> fetchLiveStreams({bool isStreamActive = true}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!isStreamActive) {
      return [];
    }
    return [
      const LiveStream(
        id: 'live_01',
        title: 'Morning Prayer & Fellowship Live Broadcast',
        hostName: 'Grace Cathedral Worship',
        hostAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        thumbnailUrl: 'https://images.unsplash.com/photo-1510915361894-db8b60106cb1',
        viewerCount: 1420,
        isLive: true,
        category: 'Live Worship & Prayer',
        startedTime: 'Started 25 mins ago',
      ),
      const LiveStream(
        id: 'live_02',
        title: 'Youth Bible Study: Overcoming Anxiety with Faith',
        hostName: 'Pastor David & Team',
        hostAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        thumbnailUrl: 'https://images.unsplash.com/photo-1529070538774-1843cb3265df',
        viewerCount: 680,
        isLive: true,
        category: 'Bible Study',
        startedTime: 'Started 10 mins ago',
      ),
    ];
  }

  Future<List<CommunityPost>> fetchCommunityPreview() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return [
      CommunityPost(
        id: 'post_1',
        authorId: 'mock_user_1',
        authorName: 'Sarah Jenkins',
        authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        content: 'Reflecting on Psalm 46:1 today: "God is our refuge and strength, an ever-present help in trouble." So grateful for His peace during stressful work weeks!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        likeCount: 48,
        commentCount: 12,
      ),
      CommunityPost(
        id: 'post_2',
        authorId: 'mock_user_2',
        authorName: 'Marcus Vance',
        authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        content: 'Our youth group worship night yesterday was truly blessed! Thanking everyone who joined to pray for our community.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likeCount: 89,
        commentCount: 24,
      ),
      CommunityPost(
        id: 'post_3',
        authorId: 'mock_user_3',
        authorName: 'Grace Community Choir',
        authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9',
        content: 'New choir rehearsal recording is live! "How Great Is Thy Faithfulness". Tap to listen and sing along.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likeCount: 134,
        commentCount: 31,
      ),
    ];
  }

  Future<ConnectSummary> fetchConnectSummary({int unreadCount = 3}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ConnectSummary(
      unreadMessagesCount: unreadCount,
      activeGroupsCount: 4,
      missedCallsCount: 0,
      latestMessageSender: 'Grace Prayer Group',
      latestMessagePreview: 'Amen! We will be praying for your family today 🙏',
      latestMessageTime: '10:42 AM',
    );
  }

  Future<List<PrayerRequest>> fetchPrayerRequests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      PrayerRequest(
        id: 'p_1',
        authorId: 'mock_user_1',
        authorName: 'Hannah Lee',
        title: 'Healing for my grandmother',
        requestText: 'Please join me in praying for my grandma who is undergoing surgery tomorrow morning.',
        prayingCount: 56,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PrayerRequest(
        id: 'p_2',
        authorId: 'mock_user_2',
        authorName: 'Daniel Smith',
        title: 'Guidance in new job transition',
        requestText: 'Asking for wisdom and peace as I start a new career path next week.',
        prayingCount: 34,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
