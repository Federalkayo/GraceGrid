import 'package:flutter/material.dart';
import 'package:gracegride2/domain/models/user_profile.dart';

class HomeHeader extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onTapProfile;
  final VoidCallback onTapNotifications;

  const HomeHeader({
    super.key,
    required this.userProfile,
    required this.onTapProfile,
    required this.onTapNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // GraceGrid Logo Wordmark
          Image.asset(
            isDark
                ? 'assets/logo/gracegrid-logo-dark.png'
                : 'assets/logo/gracegrid-logo-light.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          // Right icons: Notifications & Profile
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 22),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    onPressed: onTapNotifications,
                    tooltip: 'Notifications',
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                  if (userProfile.unreadNotificationsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onTapProfile,
                child: userProfile.isSignedIn
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: primaryBlue,
                        backgroundImage: userProfile.avatarUrl.isNotEmpty
                            ? NetworkImage(userProfile.avatarUrl)
                            : null,
                        child: userProfile.avatarUrl.isNotEmpty
                            ? null
                            : Text(
                                userProfile.name.isNotEmpty
                                    ? userProfile.name[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
