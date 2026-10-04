import 'package:flutter/material.dart';
import '../auth/auth_notifier.dart';
import '../../core/auth_gate.dart';
import '../../../data/services/post_service.dart';
import '../../../domain/models/community_post.dart';

class SocialView extends StatefulWidget {
  final AuthNotifier authNotifier;

  const SocialView({super.key, required this.authNotifier});

  @override
  State<SocialView> createState() => _SocialViewState();
}

class _SocialViewState extends State<SocialView> {
  final PostService _postService = PostService.instance;

  List<CommunityPost> _posts = [];
  bool _loading = true;
  bool _hasError = false;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = widget.authNotifier.userId;
    widget.authNotifier.addListener(_onAuthChanged);
    _loadFeed();
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    // Reload feed when the user changes (sign in/out/switch)
    final currentUserId = widget.authNotifier.userId;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    final posts = await _postService.fetchFeed();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
      _hasError = false;
    });
  }

  Future<void> _onCreatePost() async {
    if (!await requireAuth(context, widget.authNotifier)) return;
    if (!mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );

    if (result == null || result.trim().isEmpty) return;

    final newPost = await _postService.createPost(result);
    if (!mounted) return;
    if (newPost != null) {
      setState(() => _posts.insert(0, newPost));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post. Please try again.')),
      );
    }
  }

  Future<void> _onToggleLike(int index) async {
    if (!await requireAuth(context, widget.authNotifier)) return;
    if (!mounted) return;

    final post = _posts[index];
    // Optimistic update
    setState(() {
      _posts[index] = post.copyWith(
        isLikedByMe: !post.isLikedByMe,
        likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
      );
    });

    final newCount = await _postService.toggleLike(
      post.id,
      currentlyLiked: post.isLikedByMe,
    );

    if (!mounted) return;
    if (newCount != null) {
      setState(() {
        _posts[index] = _posts[index].copyWith(likeCount: newCount);
      });
    } else {
      // Revert on failure
      setState(() => _posts[index] = post);
    }
  }

  Future<void> _onTapComments(int index) async {
    if (!await requireAuth(context, widget.authNotifier)) return;
    if (!mounted) return;

    final post = _posts[index];
    final commentCount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        postId: post.id,
        postService: _postService,
        isDark: Theme.of(ctx).brightness == Brightness.dark,
      ),
    );

    // Update the local comment count from the sheet's returned value
    if (commentCount != null && mounted) {
      setState(() {
        _posts[index] = _posts[index].copyWith(commentCount: commentCount);
      });
    }
  }

  Future<void> _onDeletePost(int index) async {
    final post = _posts[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _postService.deletePost(post.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _posts.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people_alt, color: primaryBlue),
            const SizedBox(width: 8),
            const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add),
            onPressed: _onCreatePost,
          ),
        ],
      ),
      body: _loading
          ? _SocialShimmerFeed(isDark: isDark)
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Failed to load feed'),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _loadFeed, child: const Text('Retry')),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('No posts yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to share something!',
                            style: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _onCreatePost,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Create Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      color: primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return _PostCard(
                            post: _posts[index],
                            primaryBlue: primaryBlue,
                            isDark: isDark,
                            isOwner: _posts[index].authorId == widget.authNotifier.userId,
                            onLike: () => _onToggleLike(index),
                            onComment: () => _onTapComments(index),
                            onDelete: () => _onDeletePost(index),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ──────────────────────────────────────────────
// Post Card (same visual design as original)
// ──────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final Color primaryBlue;
  final bool isDark;
  final bool isOwner;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.primaryBlue,
    required this.isDark,
    required this.isOwner,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryBlue.withValues(alpha: 0.15),
                backgroundImage: post.authorAvatar.isNotEmpty
                    ? NetworkImage(post.authorAvatar)
                    : null,
                child: post.authorAvatar.isEmpty
                    ? Text(
                        post.authorName.isNotEmpty
                            ? post.authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(post.timeAgo,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                  ],
                )
              else
                const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      post.isLikedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: post.isLikedByMe ? const Color(0xFFEF4444) : primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: primaryBlue),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Create Post Sheet
// ──────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final bool isDark;
  const _CreatePostSheet({required this.isDark});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  bool _canPost = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final canPost = _controller.text.trim().isNotEmpty;
      if (canPost != _canPost) setState(() => _canPost = canPost);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create Post',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton(
                  onPressed: _canPost ? () => Navigator.pop(context, _controller.text) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                maxLength: 1000,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Share a thought, testimony, or encouragement...',
                  hintStyle: TextStyle(
                    color: (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                        .withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Comments Sheet
// ──────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final PostService postService;
  final bool isDark;

  const _CommentsSheet({
    required this.postId,
    required this.postService,
    required this.isDark,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  List<PostComment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    final comments = await widget.postService.fetchComments(widget.postId);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final comment = await widget.postService.addComment(widget.postId, text);
    if (!mounted) return;

    if (comment != null) {
      _controller.clear();
      setState(() {
        _comments.add(comment);
        _sending = false;
      });
    } else {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_comments.length);
        }
      },
      child: Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle + Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Comments (${_comments.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _loading
                ? _CommentsShimmerList(isDark: isDark)
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet. Be the first!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) {
                          final c = _comments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: primaryBlue.withValues(alpha: 0.15),
                                  backgroundImage: c.authorAvatar.isNotEmpty
                                      ? NetworkImage(c.authorAvatar)
                                      : null,
                                  child: c.authorAvatar.isEmpty
                                      ? Text(
                                          c.authorName.isNotEmpty
                                              ? c.authorName[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.authorName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(width: 6),
                                          Text(c.timeAgo,
                                              style: const TextStyle(
                                                  fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(c.content, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                              .withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _submitComment,
                  icon: _sending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
                        )
                      : Icon(Icons.send_rounded, color: primaryBlue, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ──────────────────────────────────────────────
// Shimmer Loading Skeleton Widgets
// ──────────────────────────────────────────────

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = widget.isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, -0.3),
              end: Alignment(_animation.value + 1, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SocialShimmerFeed extends StatelessWidget {
  final bool isDark;

  const _SocialShimmerFeed({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final cardBg = isDark
        ? const Color(0xFF111827)
        : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return ShimmerLoading(
      isDark: isDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: placeholderColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: placeholderColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: placeholderColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 28,
                      decoration: BoxDecoration(
                        color: placeholderColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        color: placeholderColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommentsShimmerList extends StatelessWidget {
  final bool isDark;

  const _CommentsShimmerList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return ShimmerLoading(
      isDark: isDark,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

