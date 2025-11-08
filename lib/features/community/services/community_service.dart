import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post.dart';
import '../models/post_comment.dart';

class CommunityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get community feed with user information
  Future<List<CommunityPost>> getFeed({int limit = 50, int offset = 0}) async {
    final response = await _supabase
        .from('community_posts')
        .select('*')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    // Fetch user profiles separately
    final posts = response as List;
    final userIds = posts.map((p) => p['user_id'] as String).toSet().toList();

    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, display_name, avatar_url')
        .inFilter('id', userIds);

    final profilesMap = {
      for (var profile in profilesResponse as List)
        profile['id'] as String: profile,
    };

    return posts.map((json) {
      final profile = profilesMap[json['user_id'] as String];
      return CommunityPost.fromJson({
        ...json,
        'user_display_name': profile?['display_name'],
        'user_avatar_url': profile?['avatar_url'],
      });
    }).toList();
  }

  /// Get community feed with real-time updates
  Stream<List<CommunityPost>> getFeedStream({int limit = 50}) {
    return _supabase
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .asyncMap((posts) async {
          if (posts.isEmpty) return <CommunityPost>[];

          // Fetch user profiles for all posts
          final userIds = posts
              .map((p) => p['user_id'] as String)
              .toSet()
              .toList();

          final profilesResponse = await _supabase
              .from('profiles')
              .select('id, display_name, avatar_url')
              .inFilter('id', userIds);

          final profilesMap = {
            for (var profile in profilesResponse as List)
              profile['id'] as String: profile,
          };

          return posts.map((json) {
            final profile = profilesMap[json['user_id'] as String];
            return CommunityPost.fromJson({
              ...json,
              'user_display_name': profile?['display_name'],
              'user_avatar_url': profile?['avatar_url'],
            });
          }).toList();
        });
  }

  /// Create a new post
  Future<CommunityPost> createPost({
    required String content,
    List<String>? mediaUrls,
    String? catchLogId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('community_posts')
        .insert({
          'user_id': userId,
          'content': content,
          'media_urls': mediaUrls,
          'catch_log_id': catchLogId,
        })
        .select()
        .single();

    // Fetch user profile
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return CommunityPost.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Delete a post (own posts or admin/moderator)
  Future<void> deletePost(String postId) async {
    await _supabase.from('community_posts').delete().eq('id', postId);
  }

  /// Update a post (own posts only)
  Future<CommunityPost> updatePost({
    required String postId,
    required String content,
    List<String>? mediaUrls,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('community_posts')
        .update({
          'content': content,
          'media_urls': mediaUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId)
        .select()
        .single();

    // Fetch user profile
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return CommunityPost.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Get posts by user
  Future<List<CommunityPost>> getUserPosts(String userId) async {
    final response = await _supabase
        .from('community_posts')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Fetch user profile
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return (response as List).map((json) {
      return CommunityPost.fromJson({
        ...json,
        'user_display_name': profileResponse['display_name'],
        'user_avatar_url': profileResponse['avatar_url'],
      });
    }).toList();
  }

  /// Get a single post by ID
  Future<CommunityPost> getPost(String postId) async {
    final response = await _supabase
        .from('community_posts')
        .select('*')
        .eq('id', postId)
        .single();

    // Fetch user profile
    final userId = response['user_id'] as String;
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return CommunityPost.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  // ============= LIKES =============

  /// Toggle like on a post (like if not liked, unlike if already liked)
  Future<bool> toggleLike(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if already liked
    final existingLike = await _supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingLike != null) {
      // Unlike
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      return false; // Unliked
    } else {
      // Like
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      return true; // Liked
    }
  }

  /// Check if current user has liked a post
  Future<bool> hasLiked(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final like = await _supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return like != null;
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    final response = await _supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId);

    return (response as List).length;
  }

  // ============= COMMENTS =============

  /// Get comments for a post
  Future<List<PostComment>> getComments(String postId) async {
    final response = await _supabase
        .from('post_comments')
        .select('*')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final comments = response as List;
    final userIds = comments
        .map((c) => c['user_id'] as String)
        .toSet()
        .toList();

    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, display_name, avatar_url')
        .inFilter('id', userIds);

    final profilesMap = {
      for (var profile in profilesResponse as List)
        profile['id'] as String: profile,
    };

    return comments.map((json) {
      final profile = profilesMap[json['user_id'] as String];
      return PostComment.fromJson({
        ...json,
        'user_display_name': profile?['display_name'],
        'user_avatar_url': profile?['avatar_url'],
      });
    }).toList();
  }

  /// Get comments for a post with real-time updates
  Stream<List<PostComment>> getCommentsStream(String postId) {
    return _supabase
        .from('post_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .asyncMap((comments) async {
          if (comments.isEmpty) return <PostComment>[];

          final userIds = comments
              .map((c) => c['user_id'] as String)
              .toSet()
              .toList();

          final profilesResponse = await _supabase
              .from('profiles')
              .select('id, display_name, avatar_url')
              .inFilter('id', userIds);

          final profilesMap = {
            for (var profile in profilesResponse as List)
              profile['id'] as String: profile,
          };

          return comments.map((json) {
            final profile = profilesMap[json['user_id'] as String];
            return PostComment.fromJson({
              ...json,
              'user_display_name': profile?['display_name'],
              'user_avatar_url': profile?['avatar_url'],
            });
          }).toList();
        });
  }

  /// Add a comment to a post
  Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('post_comments')
        .insert({'post_id': postId, 'user_id': userId, 'content': content})
        .select()
        .single();

    // Fetch user profile
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return PostComment.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _supabase.from('post_comments').delete().eq('id', commentId);
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    final response = await _supabase
        .from('post_comments')
        .select('id')
        .eq('post_id', postId);

    return (response as List).length;
  }
}
