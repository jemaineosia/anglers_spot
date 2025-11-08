import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community_post.dart';
import '../models/post_comment.dart';
import '../services/community_service.dart';

final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService();
});

/// Stream-based provider for real-time feed updates
/// Automatically updates when:
/// - New posts are created
/// - Posts are updated or deleted
/// - Uses Supabase Realtime for instant synchronization
final communityFeedStreamProvider =
    StreamProvider.autoDispose<List<CommunityPost>>((ref) {
      final service = ref.watch(communityServiceProvider);
      return service.getFeedStream();
    });

/// Stream-based provider for real-time comment updates on a specific post
/// Automatically updates when:
/// - New comments are added
/// - Comments are deleted
/// - Uses Supabase Realtime for instant synchronization
final postCommentsStreamProvider = StreamProvider.autoDispose
    .family<List<PostComment>, String>((ref, postId) {
      final service = ref.watch(communityServiceProvider);
      return service.getCommentsStream(postId);
    });

// Legacy FutureProvider (kept for compatibility)
final communityFeedProvider = FutureProvider.autoDispose<List<CommunityPost>>((
  ref,
) async {
  final service = ref.watch(communityServiceProvider);
  return await service.getFeed();
});

final userPostsProvider = FutureProvider.autoDispose
    .family<List<CommunityPost>, String>((ref, userId) async {
      final service = ref.watch(communityServiceProvider);
      return await service.getUserPosts(userId);
    });
