import 'package:flutter/material.dart';

class DemoControlPanel extends StatelessWidget {
  final bool isSignedIn;
  final bool hasReadingHistory;
  final bool isLiveActive;
  final bool isListeningSermon;
  final int unreadCount;
  final bool isDarkMode;
  final Function(bool) onToggleSignedIn;
  final Function(bool) onToggleReadingHistory;
  final Function(bool) onToggleLive;
  final Function(bool) onToggleSermon;
  final Function(int) onToggleUnreadCount;
  final VoidCallback onToggleTheme;
  final VoidCallback onResetState;

  const DemoControlPanel({
    super.key,
    required this.isSignedIn,
    required this.hasReadingHistory,
    required this.isLiveActive,
    required this.isListeningSermon,
    required this.unreadCount,
    required this.isDarkMode,
    required this.onToggleSignedIn,
    required this.onToggleReadingHistory,
    required this.onToggleLive,
    required this.onToggleSermon,
    required this.onToggleUnreadCount,
    required this.onToggleTheme,
    required this.onResetState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text(
                'Personalization & State Controls',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 18),
                onPressed: onToggleTheme,
                tooltip: 'Toggle Dark/Light Mode',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: onResetState,
                tooltip: 'Reset Dashboard State',
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // User Auth Mode
                ChoiceChip(
                  label: Text(isSignedIn ? 'Signed In (Grace)' : 'Guest Mode'),
                  selected: isSignedIn,
                  onSelected: (val) => onToggleSignedIn(val),
                  selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                // Reading History
                ChoiceChip(
                  label: Text(hasReadingHistory ? 'Has Reading History' : 'New User (No History)'),
                  selected: hasReadingHistory,
                  onSelected: (val) => onToggleReadingHistory(val),
                  selectedColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                // Live Stream Active
                ChoiceChip(
                  label: Text(isLiveActive ? '📹 Live Stream Active' : '📹 No Stream'),
                  selected: isLiveActive,
                  onSelected: (val) => onToggleLive(val),
                  selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                // Sermon Listening State
                ChoiceChip(
                  label: Text(isListeningSermon ? '🎤 Resume Listening' : '🎤 New Sermon'),
                  selected: isListeningSermon,
                  onSelected: (val) => onToggleSermon(val),
                  selectedColor: Colors.amber.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                // Unread messages
                ChoiceChip(
                  label: Text(unreadCount > 0 ? '💬 3 Unread Messages' : '💬 0 Unread'),
                  selected: unreadCount > 0,
                  onSelected: (val) => onToggleUnreadCount(val ? 3 : 0),
                  selectedColor: Colors.blue.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
