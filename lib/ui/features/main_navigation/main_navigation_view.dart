import 'package:flutter/material.dart';

import '../auth/auth_notifier.dart';
import '../home/view_models/home_view_model.dart';
import '../home/views/home_view.dart';
import '../bible/bible_view.dart';
import '../social/social_view.dart';
import '../connect/connect_view.dart';
import '../worship/worship_view.dart';
import '../prayer/prayer_view.dart';
import '../live/live_view.dart';
import '../more/more_view.dart';

class MainNavigationView extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final AuthNotifier authNotifier;

  const MainNavigationView({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.authNotifier,
  });

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;
  late final HomeViewModel _homeViewModel;

  Widget? _overlayView;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel()..loadDashboard();

    // Listen to auth changes so the UI updates reactively
    widget.authNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthChanged);
    _homeViewModel.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    // Refresh home dashboard when auth state changes
    _homeViewModel.syncAuthState(widget.authNotifier);
    setState(() {});
  }

  void _navigateToFeature(String feature) {
    setState(() {
      _overlayView = null;
      switch (feature.toLowerCase()) {
        case 'home':
          _currentIndex = 0;
          break;
        case 'bible':
          _currentIndex = 1;
          break;
        case 'social':
        case 'community':
          _currentIndex = 2;
          break;
        case 'connect':
        case 'messages':
          _currentIndex = 3;
          break;
        case 'worship':
        case 'sermons':
          _overlayView = const WorshipView();
          break;
        case 'prayer':
          _overlayView = PrayerView(authNotifier: widget.authNotifier);
          break;
        case 'live':
          _overlayView = const LiveView();
          break;
        case 'more':
          _currentIndex = 4;
          break;
        default:
          _currentIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    if (_overlayView != null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppBar(
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _overlayView = null),
                ),
                title: const Text('Back to GraceGrid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _overlayView!),
            ],
          ),
        ),
      );
    }

    final List<Widget> pages = [
      HomeView(
        viewModel: _homeViewModel,
        onNavigateToFeature: _navigateToFeature,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      const BibleView(),
      SocialView(authNotifier: widget.authNotifier),
      const ConnectView(),
      MoreView(
        onTapBible: () => _navigateToFeature('bible'),
        onTapWorship: () => _navigateToFeature('worship'),
        onTapPrayer: () => _navigateToFeature('prayer'),
        onTapLive: () => _navigateToFeature('live'),
        onTapSocial: () => _navigateToFeature('social'),
        onTapConnect: () => _navigateToFeature('connect'),
        onToggleTheme: widget.onToggleTheme,
        authNotifier: widget.authNotifier,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
          border: Border(
            top: BorderSide(
              color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: ListenableBuilder(
          listenable: _homeViewModel,
          builder: (context, _) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _overlayView = null;
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryBlue,
              unselectedItemColor: widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_outlined),
                  activeIcon: Icon(Icons.auto_stories),
                  label: 'Bible',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Social',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      if (_homeViewModel.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    children: [
                      const Icon(Icons.chat_bubble_rounded),
                      if (_homeViewModel.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Connect',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'More',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
