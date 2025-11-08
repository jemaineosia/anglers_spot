import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/providers/auth_provider.dart';
import '../models/community_post.dart';
import '../providers/community_provider.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityFeed extends ConsumerWidget {
  const CommunityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedStreamProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final canPost = userProfile?.role.canPost ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communityFeedStreamProvider);
        },
        child: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(communityFeedStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share something!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (canPost) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreatePostScreen(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.plus),
                        label: const Text('Create Post'),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: posts[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: canPost
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const CreatePostScreen(),
                      ),
                    )
                    .then((_) => ref.invalidate(communityFeedStreamProvider));
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }
}

class PostCard extends ConsumerWidget {
  final CommunityPost post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isOwnPost = userProfile?.id == post.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(postId: post.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, name, time
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: post.userAvatarUrl != null
                        ? NetworkImage(post.userAvatarUrl!)
                        : null,
                    child: post.userAvatarUrl == null
                        ? Icon(Icons.person, color: Colors.teal.shade700)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userDisplayName ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          timeago.format(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwnPost || (userProfile?.role.canModerate ?? false))
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showPostMenu(context, ref),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              Text(post.content),

              // Media
              if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (post.mediaUrls!.length == 1)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.mediaUrls!.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.mediaUrls!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.mediaUrls![index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],

              const SizedBox(height: 12),

              // Actions: Like, Comment
              _PostActions(post: post),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostMenu(BuildContext context, WidgetRef ref) {
    final userProfile = ref.read(userProfileProvider).value;
    final isOwnPost = userProfile?.id == post.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit option (only for own posts)
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Post'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditPostScreen(post: post),
                      ),
                    );
                    if (result == true && context.mounted) {
                      ref.invalidate(communityFeedStreamProvider);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Post'),
                      content: const Text(
                        'Are you sure you want to delete this post?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      final service = ref.read(communityServiceProvider);
                      await service.deletePost(post.id);
                      ref.invalidate(communityFeedStreamProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post deleted')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting post: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget to handle post actions (like, comment)
class _PostActions extends ConsumerStatefulWidget {
  final CommunityPost post;

  const _PostActions({required this.post});

  @override
  ConsumerState<_PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends ConsumerState<_PostActions> {
  bool? _isLiked;
  int? _likeCount;
  int? _commentCount;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final service = ref.read(communityServiceProvider);

    try {
      final results = await Future.wait([
        service.hasLiked(widget.post.id),
        service.getLikeCount(widget.post.id),
        service.getCommentCount(widget.post.id),
      ]);

      if (mounted) {
        setState(() {
          _isLiked = results[0] as bool;
          _likeCount = results[1] as int;
          _commentCount = results[2] as int;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
    }
  }

  Future<void> _toggleLike() async {
    final service = ref.read(communityServiceProvider);
    final userProfile = ref.read(userProfileProvider).value;

    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to like posts')),
        );
      }
      return;
    }

    // Optimistic update
    final wasLiked = _isLiked ?? false;
    setState(() {
      _isLiked = !wasLiked;
      _likeCount = (_likeCount ?? 0) + (wasLiked ? -1 : 1);
    });

    try {
      await service.toggleLike(widget.post.id);
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount = (_likeCount ?? 0) + (wasLiked ? 1 : -1);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _toggleLike,
          icon: Icon(
            _isLiked == true ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: _isLiked == true ? Colors.red : null,
          ),
          label: Text('${_likeCount ?? widget.post.likesCount}'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: widget.post.id),
              ),
            );
          },
          icon: const Icon(LucideIcons.messageCircle, size: 18),
          label: Text('${_commentCount ?? widget.post.commentsCount}'),
        ),
      ],
    );
  }
}
