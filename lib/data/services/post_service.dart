import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/community_post.dart';
import 'supabase_service.dart';

/// Service for community posts, likes, and comments via Supabase.
class PostService {
  PostService._();
  static final PostService instance = PostService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Fetch the community feed (newest first).
  /// Joins with `profiles` to get author info.
  /// Checks `post_likes` to know if current user liked each post.
  Future<List<CommunityPost>> fetchFeed({int limit = 30, int offset = 0}) async {
    try {
      final userId = _client.auth.currentUser?.id;

      final data = await _client
          .from('posts')
          .select('*, profiles!posts_profiles_fkey(display_name, avatar_url)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // If signed in, fetch the set of post IDs the user has liked
      Set<String> likedPostIds = {};
      if (userId != null && data.isNotEmpty) {
        final postIds = data.map((row) => row['id'] as String).toList();
        final likes = await _client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', userId)
            .inFilter('post_id', postIds);
        likedPostIds = likes.map((r) => r['post_id'] as String).toSet();
      }

      return data.map((json) {
        final postId = json['id'] as String;
        return CommunityPost.fromJson(json, isLikedByMe: likedPostIds.contains(postId));
      }).toList();
    } catch (e) {
      debugPrint('PostService.fetchFeed error: $e');
      return [];
    }
  }

  /// Create a new post. Returns the created post or null on failure.
  Future<CommunityPost?> createPost(String content) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('posts')
          .insert({'user_id': user.id, 'content': content.trim()})
          .select('*, profiles!posts_profiles_fkey(display_name, avatar_url)')
          .single();

      return CommunityPost.fromJson(data, isLikedByMe: false);
    } catch (e) {
      debugPrint('PostService.createPost error: $e');
      return null;
    }
  }

  /// Delete a post (only own posts — RLS enforced server-side).
  Future<bool> deletePost(String postId) async {
    try {
      await _client.from('posts').delete().eq('id', postId);
      return true;
    } catch (e) {
      debugPrint('PostService.deletePost error: $e');
      return false;
    }
  }

  /// Toggle like on a post. Returns the new like count, or null on failure.
  Future<int?> toggleLike(String postId, {required bool currentlyLiked}) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      if (currentlyLiked) {
        // Unlike: remove from post_likes and decrement
        await _client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
        await _client.rpc('decrement_like_count', params: {'p_post_id': postId});
      } else {
        // Like: insert into post_likes and increment
        await _client
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': user.id});
        await _client.rpc('increment_like_count', params: {'p_post_id': postId});
      }

      // Fetch the updated count
      final row = await _client
          .from('posts')
          .select('like_count')
          .eq('id', postId)
          .single();
      return row['like_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('PostService.toggleLike error: $e');
      return null;
    }
  }

  /// Fetch comments for a post, newest last.
  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final data = await _client
          .from('post_comments')
          .select('*, profiles!post_comments_profiles_fkey(display_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return data.map((json) => PostComment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('PostService.fetchComments error: $e');
      return [];
    }
  }

  /// Add a comment to a post. Returns the created comment or null.
  Future<PostComment?> addComment(String postId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('post_comments')
          .insert({
            'post_id': postId,
            'user_id': user.id,
            'content': content.trim(),
          })
          .select('*, profiles!post_comments_profiles_fkey(display_name, avatar_url)')
          .single();

      // Increment comment count on the post
      await _client.rpc('increment_comment_count', params: {'p_post_id': postId});

      return PostComment.fromJson(data);
    } catch (e) {
      debugPrint('PostService.addComment error: $e');
      return null;
    }
  }
}
