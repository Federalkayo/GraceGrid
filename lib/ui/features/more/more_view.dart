import 'package:flutter/material.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';

class MoreView extends StatelessWidget {
  final VoidCallback onTapWorship;
  final VoidCallback onTapLive;
  final VoidCallback onTapPrayer;
  final VoidCallback onTapBible;
  final VoidCallback onTapSocial;
  final VoidCallback onTapConnect;
  final VoidCallback onToggleTheme;
  final AuthNotifier authNotifier;
  final bool isDarkMode;

  const MoreView({
    super.key,
    required this.onTapWorship,
    required this.onTapLive,
    required this.onTapPrayer,
    required this.onTapBible,
    required this.onTapSocial,
    required this.onTapConnect,
    required this.onToggleTheme,
    required this.authNotifier,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return ListenableBuilder(
      listenable: authNotifier,
      builder: (context, _) {
        final isSignedIn = authNotifier.isAuthenticated;
        final profile = authNotifier.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('More & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  onTap: isSignedIn
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfileScreen(authNotifier: authNotifier),
                            ),
                          );
                        }
                      : null,
                  leading: CircleAvatar(
                    backgroundColor: primaryBlue,
                    backgroundImage: (isSignedIn && profile.avatarUrl.isNotEmpty)
                        ? NetworkImage(profile.avatarUrl)
                        : null,
                    child: (isSignedIn && profile.avatarUrl.isNotEmpty)
                        ? null
                        : Text(
                            isSignedIn && profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  title: Text(
                    isSignedIn ? profile.name : 'Guest User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isSignedIn
                        ? 'Tap to edit profile'
                        : 'Tap to sign in or create account',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSignedIn
                      ? TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Sign Out?'),
                                content: const Text(
                                    'You will still be able to use Bible, Worship, and other offline features.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Sign Out',
                                        style: TextStyle(color: Color(0xFFEF4444))),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await authNotifier.signOut();
                            }
                          },
                          child: Text('Sign Out',
                              style: TextStyle(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AuthScreen(authNotifier: authNotifier),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Sign In',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('App Modules', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(Icons.auto_stories, color: primaryBlue),
                title: const Text('Holy Bible'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTapBible,
              ),
              ListTile(
                leading: Icon(Icons.graphic_eq, color: primaryBlue),
                title: const Text('Worship & Sermons'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTapWorship,
              ),
              ListTile(
                leading: Icon(Icons.volunteer_activism, color: primaryBlue),
                title: const Text('Prayer Center'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTapPrayer,
              ),
              ListTile(
                leading: Icon(Icons.live_tv, color: primaryBlue),
                title: const Text('Live Streams'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTapLive,
              ),
              ListTile(
                leading: Icon(Icons.people_alt, color: primaryBlue),
                title: const Text('Community Feed'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTapSocial,
              ),
              ListTile(
                leading: Icon(Icons.chat_outlined, color: primaryBlue),
                title: const Text('Connect & Messages'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onTapConnect,
              ),
              const Divider(height: 24),
              const Text('Preferences', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: primaryBlue),
                title: const Text('Appearance'),
                subtitle: Text(isDarkMode ? 'Dark Theme' : 'Light Theme'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (_) => onToggleTheme(),
                  activeThumbColor: primaryBlue,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Notification Preferences'),
                subtitle: const Text('Daily verse, prayer alerts, sermon releases'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About GraceGrid'),
                subtitle: const Text('v1.0.0 • Modern Christian Social Network'),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
