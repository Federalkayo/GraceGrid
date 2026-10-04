import 'package:flutter/foundation.dart';
import '../../auth/auth_notifier.dart';
import '../../../../data/repositories/grace_grid_repository.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../../domain/models/bible_reading.dart';
import '../../../../domain/models/daily_verse.dart';
import '../../../../domain/models/sermon.dart';
import '../../../../domain/models/live_stream.dart';
import '../../../../domain/models/community_post.dart';
import '../../../../domain/models/prayer.dart';
import '../../../../domain/models/connect_item.dart';

class HomeViewModel extends ChangeNotifier {
  final GraceGridRepository _repository;

  HomeViewModel({GraceGridRepository? repository})
      : _repository = repository ?? GraceGridRepository();

  // State data
  UserProfile _userProfile = UserProfile.guest();
  BibleReadingProgress _bibleProgress = BibleReadingProgress.empty();
  DailyVerse? _dailyVerse;
  Sermon? _featuredSermon;
  List<LiveStream> _liveStreams = [];
  List<CommunityPost> _communityPosts = [];
  ConnectSummary _connectSummary = const ConnectSummary(
    unreadMessagesCount: 0,
    activeGroupsCount: 0,
    missedCallsCount: 0,
    latestMessageSender: '',
    latestMessagePreview: '',
    latestMessageTime: '',
  );
  List<PrayerRequest> _prayerRequests = [];

  // Independent Section Loading States
  bool _isUserLoading = true;
  bool _isBibleLoading = true;
  bool _isDailyVerseLoading = true;
  bool _isWorshipLoading = true;
  bool _isLiveLoading = true;
  bool _isSocialLoading = true;
  bool _isConnectLoading = true;
  bool _isPrayerLoading = true;

  // Personalization & Interactive Controls
  bool _forcedGuest = false;
  bool _hasReadingHistory = true;
  bool _isLiveActive = true;
  bool _isListeningSermon = true;
  int _unreadCount = 3;

  // Getters for Data
  UserProfile get userProfile => _userProfile;
  BibleReadingProgress get bibleProgress => _bibleProgress;
  DailyVerse? get dailyVerse => _dailyVerse;
  Sermon? get featuredSermon => _featuredSermon;
  List<LiveStream> get liveStreams => _liveStreams;
  List<CommunityPost> get communityPosts => _communityPosts;
  ConnectSummary get connectSummary => _connectSummary;
  List<PrayerRequest> get prayerRequests => _prayerRequests;

  // Getters for Independent Loading
  bool get isUserLoading => _isUserLoading;
  bool get isBibleLoading => _isBibleLoading;
  bool get isDailyVerseLoading => _isDailyVerseLoading;
  bool get isWorshipLoading => _isWorshipLoading;
  bool get isLiveLoading => _isLiveLoading;
  bool get isSocialLoading => _isSocialLoading;
  bool get isConnectLoading => _isConnectLoading;
  bool get isPrayerLoading => _isPrayerLoading;

  // Personalization State Getters
  bool get isSignedIn => _userProfile.isSignedIn;
  bool get hasReadingHistory => _hasReadingHistory;
  bool get isLiveActive => _isLiveActive;
  bool get isListeningSermon => _isListeningSermon;
  int get unreadCount => _unreadCount;

  // Welcome greeting logic based on local time
  String get timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // Initialize and load all sections asynchronously without blocking UI
  void loadDashboard() {
    _loadUserProfile();
    _loadBibleSection();
    _loadDailyVerseSection();
    _loadWorshipSection();
    _loadLiveSection();
    _loadSocialSection();
    _loadConnectSection();
    _loadPrayerSection();
  }

  Future<void> _loadUserProfile() async {
    _isUserLoading = true;
    notifyListeners();
    try {
      _userProfile = await _repository.getUserProfile(forcedGuest: _forcedGuest);
    } finally {
      _isUserLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBibleSection() async {
    _isBibleLoading = true;
    notifyListeners();
    try {
      _bibleProgress = await _repository.getBibleProgress(hasHistory: _hasReadingHistory);
    } finally {
      _isBibleLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDailyVerseSection() async {
    _isDailyVerseLoading = true;
    notifyListeners();
    try {
      _dailyVerse = await _repository.getDailyVerse();
    } finally {
      _isDailyVerseLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadWorshipSection() async {
    _isWorshipLoading = true;
    notifyListeners();
    try {
      _featuredSermon = await _repository.getFeaturedSermon(isListening: _isListeningSermon);
    } finally {
      _isWorshipLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLiveSection() async {
    _isLiveLoading = true;
    notifyListeners();
    try {
      _liveStreams = await _repository.getLiveStreams(isStreamActive: _isLiveActive);
    } finally {
      _isLiveLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSocialSection() async {
    _isSocialLoading = true;
    notifyListeners();
    try {
      _communityPosts = await _repository.getCommunityPreview();
    } finally {
      _isSocialLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadConnectSection() async {
    _isConnectLoading = true;
    notifyListeners();
    try {
      _connectSummary = await _repository.getConnectSummary(unreadCount: _unreadCount);
    } finally {
      _isConnectLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPrayerSection() async {
    _isPrayerLoading = true;
    notifyListeners();
    try {
      _prayerRequests = await _repository.getPrayerRequests();
    } finally {
      _isPrayerLoading = false;
      notifyListeners();
    }
  }

  // Interactive Actions
  Future<void> toggleSaveDailyVerse() async {
    if (_dailyVerse == null) return;
    final newSaved = await _repository.toggleSaveVerse(_dailyVerse!.id);
    _dailyVerse = _dailyVerse!.copyWith(isSaved: newSaved);
    notifyListeners();
  }

  Future<void> toggleSermonPlayPause() async {
    if (_featuredSermon == null) return;
    final isListening = !_featuredSermon!.isListening;
    _featuredSermon = _featuredSermon!.copyWith(isListening: isListening);
    notifyListeners();
  }

  // Sync auth state from AuthNotifier (real Supabase auth)
  void syncAuthState(AuthNotifier authNotifier) {
    _userProfile = authNotifier.userProfile;
    _forcedGuest = !authNotifier.isAuthenticated;
    notifyListeners();
  }

  // Personalization Toggles (kept for backward compat)
  void toggleSignedIn(bool isSignedIn) async {
    _forcedGuest = !isSignedIn;
    await _repository.toggleUserSignIn(isSignedIn);
    _loadUserProfile();
  }

  void toggleReadingHistory(bool hasHistory) {
    _hasReadingHistory = hasHistory;
    _loadBibleSection();
  }

  void toggleLiveActive(bool isActive) {
    _isLiveActive = isActive;
    _loadLiveSection();
  }

  void toggleSermonListening(bool isListening) {
    _isListeningSermon = isListening;
    _loadWorshipSection();
  }

  void toggleUnreadMessages(int count) {
    _unreadCount = count;
    _loadConnectSection();
  }

  void resetDashboardState() {
    _forcedGuest = false;
    _hasReadingHistory = true;
    _isLiveActive = true;
    _isListeningSermon = true;
    _unreadCount = 3;
    loadDashboard();
  }
}
