import 'package:flutter/material.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Daily Verse Reminder',
        'body': 'Proverbs 3:5-6 is your daily verse for today.',
        'time': '10m ago',
        'icon': Icons.menu_book,
        'color': Colors.amber,
        'unread': true,
      },
      {
        'title': 'New Sermon Uploaded',
        'body': 'Pastor Michael published "Walking in Grace & Unshakable Purpose".',
        'time': '1h ago',
        'icon': Icons.podcasts,
        'color': Colors.indigo,
        'unread': true,
      },
      {
        'title': 'Prayer Wall Update',
        'body': '12 brothers & sisters prayed for your request today.',
        'time': '3h ago',
        'icon': Icons.favorite,
        'color': Colors.pinkAccent,
        'unread': false,
      },
      {
        'title': 'Live Worship Broadcast',
        'body': 'Grace Cathedral Worship is currently broadcasting live!',
        'time': '5h ago',
        'icon': Icons.live_tv,
        'color': Colors.redAccent,
        'unread': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Mark all as read'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: notif['unread']
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (notif['color'] as Color).withValues(alpha: 0.15),
                    child: Icon(notif['icon'] as IconData, color: notif['color'] as Color, size: 20),
                  ),
                  title: Text(
                    notif['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    notif['body'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    notif['time'] as String,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
