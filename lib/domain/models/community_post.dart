class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
  });

  /// Parse a post row from Supabase (joined with profiles).
  factory CommunityPost.fromJson(
    Map<String, dynamic> json, {
    bool isLikedByMe = false,
  }) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CommunityPost(
      id: json['id'] as String,
      authorId: json['user_id'] as String,
      authorName: profile?['display_name'] as String? ?? 'Anonymous',
      authorAvatar: profile?['avatar_url'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLikedByMe: isLikedByMe,
    );
  }

  /// Human-readable relative time string.
  String get timeAgo {
    final diff = DateTime.now().toUtc().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

/// A comment on a community post.
class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      authorName: profile?['display_name'] as String? ?? 'Anonymous',
      authorAvatar: profile?['avatar_url'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
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
}

