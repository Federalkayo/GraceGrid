import 'package:flutter/material.dart';

class LiveView extends StatelessWidget {
  const LiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const liveRed = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: liveRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.live_tv_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GraceGrid Live',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Watch live services & events',
                          style:
                              TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Notification bell
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.notifications_outlined,
                            color: textSecondary, size: 20),
                        onPressed: () {},
                        tooltip: 'Live Notifications',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── NOW LIVE HERO CARD ──────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E2E), Color(0xFF2D1B42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D1B42).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    Positioned(
                      left: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.graphic_eq_rounded,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Live badge row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: liveRed,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          liveRed.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'LIVE NOW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '1.4k watching',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Title
                          const Text(
                            'Morning Prayer &\nFellowship Live',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle info
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.church_rounded,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.5)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Grace Cathedral Worship',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.5)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Started 25 min ago',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Watch button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Opening Live Stream Player...')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: liveRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 22),
                              label: const Text(
                                'Watch Live',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── QUICK STATS ROW ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_alt_rounded,
                      label: '1,423',
                      subtitle: 'Online',
                      color: const Color(0xFF22C55E),
                      isDark: isDark,
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.favorite_rounded,
                      label: '256',
                      subtitle: 'Prayers',
                      color: const Color(0xFFF43F5E),
                      isDark: isDark,
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.chat_bubble_rounded,
                      label: '89',
                      subtitle: 'Chat',
                      color: primaryBlue,
                      isDark: isDark,
                      surface: surface,
                      border: border,
                    ),
                  ],
                ),
              ),
            ),

            // ── UPCOMING BROADCASTS HEADER ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Upcoming Broadcasts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── UPCOMING BROADCASTS LIST ────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _UpcomingBroadcastCard(
                    title: 'Sunday Global Worship Service',
                    schedule: 'Sunday @ 9:00 AM',
                    location: 'Grace Cathedral',
                    icon: Icons.church_rounded,
                    gradientColors: [
                      const Color(0xFF2563EB),
                      const Color(0xFF3B82F6),
                    ],
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                    daysUntil: 'In 2 days',
                  ),
                  const SizedBox(height: 10),
                  _UpcomingBroadcastCard(
                    title: 'Wednesday Night Bible Study',
                    schedule: 'Wednesday @ 7:00 PM',
                    location: 'Pastor Michael',
                    icon: Icons.menu_book_rounded,
                    gradientColors: [
                      const Color(0xFF8B5CF6),
                      const Color(0xFFA78BFA),
                    ],
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                    daysUntil: 'In 4 days',
                  ),
                  const SizedBox(height: 10),
                  _UpcomingBroadcastCard(
                    title: 'Friday Youth Night',
                    schedule: 'Friday @ 6:30 PM',
                    location: 'Youth Hall',
                    icon: Icons.groups_rounded,
                    gradientColors: [
                      const Color(0xFFF59E0B),
                      const Color(0xFFFBBF24),
                    ],
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                    daysUntil: 'In 6 days',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STAT CHIP ───────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final Color surface;
  final Color border;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF0F172A),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── UPCOMING BROADCAST CARD ─────────────────────────────────────
class _UpcomingBroadcastCard extends StatelessWidget {
  final String title;
  final String schedule;
  final String location;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryBlue;
  final String daysUntil;

  const _UpcomingBroadcastCard({
    required this.title,
    required this.schedule,
    required this.location,
    required this.icon,
    required this.gradientColors,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryBlue,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$schedule • $location',
                        style:
                            TextStyle(fontSize: 12, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Days badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysUntil,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
