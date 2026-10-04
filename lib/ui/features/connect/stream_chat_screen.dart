import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../core/theme/app_colors.dart';

/// GraceGrid-themed 1-to-1 chat screen powered by GetStream.
///
/// Uses Stream's prebuilt message list and composer widgets
/// with GraceGrid styling applied via [StreamChatTheme].
class StreamChatScreen extends StatelessWidget {
  final Channel channel;

  const StreamChatScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? AppColors.primaryBlueDark : AppColors.primaryBlueLight;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Derive the other user's info from the channel
    final otherMembers = channel.state?.members
            .where(
                (m) => m.userId != channel.client.state.currentUser?.id)
            .toList() ??
        [];
    final otherUser =
        otherMembers.isNotEmpty ? otherMembers.first.user : null;
    final displayName = otherUser?.name ?? 'Chat';
    final avatarUrl = otherUser?.image;
    final isOnline = otherUser?.online ?? false;

    final streamTheme = StreamChatThemeData(
      messageListViewTheme: StreamMessageListViewThemeData(
        backgroundColor: bg,
      ),
    );

    return StreamChatTheme(
      data: streamTheme,
      child: StreamChannel(
        channel: channel,
        child: Scaffold(
          backgroundColor: bg,
          appBar: _buildAppBar(
            context,
            isDark: isDark,
            primaryBlue: primaryBlue,
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            displayName: displayName,
            avatarUrl: avatarUrl,
            isOnline: isOnline,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamMessageListView(),
              ),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(
                    top: BorderSide(color: border, width: 0.5),
                  ),
                ),
                child: StreamMessageComposer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDark,
    required Color primaryBlue,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required String displayName,
    required String? avatarUrl,
    required bool isOnline,
  }) {
    return AppBar(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar with online indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryBlue,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Name + status / typing indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                BetterStreamBuilder<Map<User, Event>>(
                  stream: channel.state?.typingEventsStream,
                  initialData: channel.state?.typingEvents,
                  builder: (context, typingEvents) {
                    final currentUserId =
                        channel.client.state.currentUser?.id;
                    final otherTyping = typingEvents.entries
                        .where((e) => e.key.id != currentUserId)
                        .toList();

                    if (otherTyping.isNotEmpty) {
                      return Text(
                        'typing…',
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: border,
        ),
      ),
    );
  }
}
