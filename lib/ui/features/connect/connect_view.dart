import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/stream_chat_service.dart';
import 'new_dm_sheet.dart';
import 'stream_chat_screen.dart';

class ConnectView extends StatefulWidget {
  const ConnectView({super.key});

  @override
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamChannelListController? _channelListController;

  static const _groups = [
    _GroupData(
      name: 'Youth Worship Team',
      members: 24,
      description: 'Active rehearsal chat',
      icon: Icons.music_note_rounded,
      gradientStart: Color(0xFF10B981),
      gradientEnd: Color(0xFF34D399),
      isActive: true,
    ),
    _GroupData(
      name: 'Morning Prayer Fellowship',
      members: 142,
      description: 'Daily 6 AM prayer call',
      icon: Icons.favorite_rounded,
      gradientStart: Color(0xFFF59E0B),
      gradientEnd: Color(0xFFFBBF24),
      isActive: true,
    ),
    _GroupData(
      name: 'Bible Study Circle',
      members: 38,
      description: 'Weekly deep-dive discussions',
      icon: Icons.menu_book_rounded,
      gradientStart: Color(0xFF2563EB),
      gradientEnd: Color(0xFF3B82F6),
      isActive: false,
    ),
    _GroupData(
      name: 'Outreach & Missions',
      members: 67,
      description: 'Community service coordination',
      icon: Icons.volunteer_activism_rounded,
      gradientStart: Color(0xFFEC4899),
      gradientEnd: Color(0xFFF472B6),
      isActive: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _initChannelListController();
  }

  void _initChannelListController() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (_channelListController == null ||
          _channelListController?.client.state.currentUser?.id != user.id) {
        _channelListController?.dispose();
        _channelListController = StreamChannelListController(
          client: StreamChatService.instance.client,
          filter: Filter.in_('members', [user.id]),
          channelStateSort: const [
            SortOption<ChannelState>.desc(ChannelSortKey.lastUpdated)
          ],
          limit: 20,
        );
        _channelListController!.doInitialLoad();
      }
    } else {
      _channelListController?.dispose();
      _channelListController = null;
    }
  }

  @override
  void dispose() {
    _channelListController?.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_GroupData> get _filteredGroups {
    if (_searchQuery.isEmpty) return _groups;
    return _groups
        .where((g) =>
            g.name.toLowerCase().contains(_searchQuery) ||
            g.description.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _startNewConversation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send messages.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedProfile = await showModalBottomSheet<ProfileData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewDmSheet(),
    );

    if (selectedProfile == null || !mounted) return;

    await _openChatWithUser(selectedProfile.id);
  }

  Future<void> _openChatWithUser(String targetUserId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && !StreamChatService.instance.isUserConnected) {
        final metaName = user.userMetadata?['display_name'] as String? ??
            user.email?.split('@').first ??
            'User';
        final avatarUrl = user.userMetadata?['avatar_url'] as String? ?? '';
        await StreamChatService.instance.connectUser(
          userId: user.id,
          displayName: metaName,
          avatarUrl: avatarUrl,
        );
      }

      final channel = await StreamChatService.instance
          .getOrCreateDMChannel(targetUserId);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StreamChatScreen(channel: channel),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceElevated =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stay connected with your community',
                          style:
                              TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 20),
                      onPressed: _startNewConversation,
                      tooltip: 'New Message',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── SEARCH BAR ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search messages, groups...',
                    hintStyle:
                        TextStyle(fontSize: 14, color: textSecondary),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20, color: textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: textSecondary),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── TAB BAR ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 0.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: primaryBlue,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                tabs: [
                  _buildMessagesTabLabel(primaryBlue),
                  _buildTabLabel('Groups', '4', primaryBlue),
                  const Tab(text: 'Calls'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── TAB VIEWS ───────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMessagesTab(isDark, primaryBlue, surface, border,
                      textPrimary, textSecondary),
                  _buildGroupsTab(isDark, primaryBlue, surface, border,
                      textPrimary, textSecondary),
                  _buildCallsTab(
                      isDark, primaryBlue, textPrimary, textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Channel> get _safeCurrentChannels {
    final controller = _channelListController;
    if (controller == null) return [];
    final pagedValue = controller.value;
    if (pagedValue.isSuccess) {
      return pagedValue.asSuccess.items;
    }
    return [];
  }

  Widget _buildMessagesTabLabel(Color primaryBlue) {
    if (_channelListController == null) {
      return _buildTabLabel('Messages', '0', primaryBlue);
    }
    return PagedValueListenableBuilder<int, Channel>(
      valueListenable: _channelListController!,
      builder: (context, value, child) {
        final channels = _safeCurrentChannels;
        final totalUnread = channels
            .where((c) => (c.state?.unreadCount ?? 0) > 0)
            .length;
        return _buildTabLabel('Messages', '$totalUnread', primaryBlue);
      },
    );
  }

  Widget _buildTabLabel(String text, String count, Color primaryBlue) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 5),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MESSAGES TAB (DYNAMIC GETSTREAM DATA) ─────────────────
  Widget _buildMessagesTab(
    bool isDark,
    Color primaryBlue,
    Color surface,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return _buildGuestMessagesState(
        isDark,
        primaryBlue,
        surface,
        border,
        textPrimary,
        textSecondary,
      );
    }

    if (_channelListController == null) {
      _initChannelListController();
    }

    if (_channelListController == null) {
      return Center(
        child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
      );
    }

    return StreamChannelListView(
      key: ValueKey(_channelListController.hashCode),
      controller: _channelListController!,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      loadingBuilder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
        ),
      ),
      emptyBuilder: (context) => _buildEmptyMessagesState(
        textPrimary,
        textSecondary,
        primaryBlue,
      ),
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: textSecondary, size: 40),
              const SizedBox(height: 12),
              Text(
                'Could not load messages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _channelListController?.refresh(),
                child: Text('Retry', style: TextStyle(color: primaryBlue)),
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (context, channels, index, defaultWidget) {
        final channel = channels[index];

        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final currentUserId =
              Supabase.instance.client.auth.currentUser?.id;
          final otherMembers = channel.state?.members
                  .where((m) => m.userId != currentUserId)
                  .toList() ??
              [];
          final otherUser =
              otherMembers.isNotEmpty ? otherMembers.first.user : null;
          final name = (otherUser?.name ?? channel.name ?? '').toLowerCase();
          final lastMsg =
              (channel.state?.lastMessage?.text ?? '').toLowerCase();

          if (!name.contains(_searchQuery) &&
              !lastMsg.contains(_searchQuery)) {
            return const SizedBox.shrink();
          }
        }

        return _buildChannelTile(
          channel,
          isDark: isDark,
          primaryBlue: primaryBlue,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      },
    );
  }

  Widget _buildChannelTile(
    Channel channel, {
    required bool isDark,
    required Color primaryBlue,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final otherMembers = channel.state?.members
            .where((m) => m.userId != currentUserId)
            .toList() ??
        [];
    final otherUser =
        otherMembers.isNotEmpty ? otherMembers.first.user : null;
    final displayName = otherUser?.name ?? channel.name ?? 'Chat';
    final avatarUrl = otherUser?.image ?? '';
    final isOnline = otherUser?.online ?? false;
    final unreadCount = channel.state?.unreadCount ?? 0;
    final hasUnread = unreadCount > 0;

    final initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    final gradientColors =
        _getGradientForUser(otherUser?.id ?? channel.id ?? '');

    final lastMessage = channel.state?.lastMessage;
    final text = lastMessage?.text;
    final String lastMessageText;
    if (text != null && text.isNotEmpty) {
      lastMessageText = text;
    } else {
      final messages = channel.state?.messages;
      if (messages != null &&
          messages.isNotEmpty &&
          messages.last.text != null &&
          messages.last.text!.isNotEmpty) {
        lastMessageText = messages.last.text!;
      } else {
        lastMessageText = 'No messages yet';
      }
    }

    final formattedTime =
        _formatTimestamp(lastMessage?.createdAt ?? channel.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: hasUnread
            ? primaryBlue.withValues(alpha: isDark ? 0.08 : 0.04)
            : surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? primaryBlue.withValues(alpha: 0.2)
                  : border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StreamChatScreen(channel: channel),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: avatarUrl.isEmpty
                              ? LinearGradient(
                                  colors: gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  gradientColors.first.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: avatarUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF111827)
                                    : Colors.white,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: hasUnread
                                    ? primaryBlue
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessageText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasUnread
                                      ? textPrimary.withValues(alpha: 0.8)
                                      : textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientForUser(String id) {
    const gradients = [
      [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      [Color(0xFF2563EB), Color(0xFF3B82F6)],
      [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      [Color(0xFF10B981), Color(0xFF34D399)],
      [Color(0xFFEC4899), Color(0xFFF472B6)],
    ];
    final hash = id.hashCode.abs();
    return gradients[hash % gradients.length];
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final difference = now.difference(local);

    if (difference.inDays == 0 && now.day == local.day) {
      final hour = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[local.weekday - 1];
    } else {
      return '${local.month}/${local.day}';
    }
  }

  Widget _buildGuestMessagesState(
    bool isDark,
    Color primaryBlue,
    Color surface,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded,
                  size: 32, color: primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign In to Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with church members, pastors, and study groups.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to view your messages.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign In',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessagesState(
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a 1-to-1 message with a member.',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _startNewConversation,
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Start Message',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── GROUPS TAB ─────────────────────────────────────────────
  Widget _buildGroupsTab(bool isDark, Color primaryBlue, Color surface,
      Color border, Color textPrimary, Color textSecondary) {
    final items = _filteredGroups;

    if (items.isEmpty) {
      return _buildEmptySearch('groups', textPrimary, textSecondary);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final group = items[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: border.withValues(alpha: 0.5), width: 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              group.gradientStart,
                              group.gradientEnd
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: group.gradientStart
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(group.icon,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (group.isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${group.members} members • ${group.description}',
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          color: textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── CALLS TAB ──────────────────────────────────────────────
  Widget _buildCallsTab(
      bool isDark, Color primaryBlue, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_in_talk_rounded,
                  size: 36, color: primaryBlue),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Calls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a call with your community\nmembers or prayer groups.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_call, size: 18),
              label: const Text('Start a Call',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY SEARCH STATE ─────────────────────────────────────
  Widget _buildEmptySearch(
      String type, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48,
                color: textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No $type found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupData {
  final String name;
  final int members;
  final String description;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isActive;

  const _GroupData({
    required this.name,
    required this.members,
    required this.description,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.isActive,
  });
}
