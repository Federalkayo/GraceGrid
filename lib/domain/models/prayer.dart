class PrayerRequest {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String title;
  final String requestText;
  final int prayingCount;
  final DateTime createdAt;
  final bool isAnswered;
  final bool isPrayedByMe;

  const PrayerRequest({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    required this.title,
    required this.requestText,
    this.prayingCount = 0,
    required this.createdAt,
    this.isAnswered = false,
    this.isPrayedByMe = false,
  });

  factory PrayerRequest.fromJson(
    Map<String, dynamic> json, {
    bool isPrayedByMe = false,
  }) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return PrayerRequest(
      id: json['id'] as String,
      authorId: json['user_id'] as String,
      authorName: profile?['display_name'] as String? ?? 'Anonymous',
      authorAvatar: profile?['avatar_url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      requestText: json['request_text'] as String? ?? '',
      prayingCount: json['praying_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isAnswered: json['is_answered'] as bool? ?? false,
      isPrayedByMe: isPrayedByMe,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Whether the current signed-in user authored this prayer.
  bool isOwnRequest(String? currentUserId) => authorId == currentUserId;

  PrayerRequest copyWith({
    int? prayingCount,
    bool? isAnswered,
    bool? isPrayedByMe,
  }) {
    return PrayerRequest(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      title: title,
      requestText: requestText,
      prayingCount: prayingCount ?? this.prayingCount,
      createdAt: createdAt,
      isAnswered: isAnswered ?? this.isAnswered,
      isPrayedByMe: isPrayedByMe ?? this.isPrayedByMe,
    );
  }
}

