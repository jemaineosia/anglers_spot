import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/providers/auth_provider.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import '../providers/community_provider.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool? _isLiked;
  int? _likeCount;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeStatus() async {
    try {
      final service = ref.read(communityServiceProvider);
      final results = await Future.wait([
        service.hasLiked(widget.postId),
        service.getLikeCount(widget.postId),
      ]);
      if (mounted) {
        setState(() {
          _isLiked = results[0] as bool;
          _likeCount = results[1] as int;
        });
      }
    } catch (e) {
      debugPrint('Error loading like status: $e');
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
      await service.toggleLike(widget.postId);
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

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to comment')),
        );
      }
      return;
    }

    try {
      final service = ref.read(communityServiceProvider);
      await service.addComment(postId: widget.postId, content: content);
      _commentController.clear();
      // Stream will automatically update with new comment
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final service = ref.read(communityServiceProvider);
      await service.deleteComment(commentId);
      // Stream will automatically update after deletion
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: FutureBuilder<CommunityPost>(
        future: ref.read(communityServiceProvider).getPost(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final post = snapshot.data!;
          final userProfile = ref.watch(userProfileProvider).value;
          final isOwnPost = userProfile?.id == post.userId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.teal.shade100,
                                  backgroundImage: post.userAvatarUrl != null
                                      ? NetworkImage(post.userAvatarUrl!)
                                      : null,
                                  child: post.userAvatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          color: Colors.teal.shade700,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.userDisplayName ?? 'Unknown User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        timeago.format(post.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwnPost ||
                                    (userProfile?.role.canModerate ?? false))
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () =>
                                        _showPostMenu(context, post),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Content
                            Text(
                              post.content,
                              style: const TextStyle(fontSize: 16),
                            ),

                            // Media
                            if (post.mediaUrls != null &&
                                post.mediaUrls!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ...post.mediaUrls!.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Actions
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _toggleLike,
                                  icon: Icon(
                                    _isLiked == true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 20,
                                    color: _isLiked == true ? Colors.red : null,
                                  ),
                                  label: Text(
                                    '${_likeCount ?? post.likesCount}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Comment count from stream
                                Consumer(
                                  builder: (context, ref, _) {
                                    final commentsAsync = ref.watch(
                                      postCommentsStreamProvider(widget.postId),
                                    );
                                    final count = commentsAsync.maybeWhen(
                                      data: (comments) => comments.length,
                                      orElse: () => post.commentsCount,
                                    );
                                    return TextButton.icon(
                                      onPressed: null,
                                      icon: const Icon(
                                        LucideIcons.messageCircle,
                                        size: 20,
                                      ),
                                      label: Text('$count'),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Comments section with real-time updates
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comments',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            // Stream-based comments
                            Consumer(
                              builder: (context, ref, _) {
                                final commentsAsync = ref.watch(
                                  postCommentsStreamProvider(widget.postId),
                                );

                                return commentsAsync.when(
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (error, _) => Center(
                                    child: Text(
                                      'Error loading comments: $error',
                                    ),
                                  ),
                                  data: (comments) {
                                    if (comments.isEmpty) {
                                      return Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              LucideIcons.messageCircle,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No comments yet',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: comments.map((comment) {
                                        return _CommentCard(
                                          comment: comment,
                                          onDelete:
                                              userProfile?.id ==
                                                      comment.userId ||
                                                  (userProfile
                                                          ?.role
                                                          .canModerate ??
                                                      false)
                                              ? () => _deleteComment(comment.id)
                                              : null,
                                        );
                                      }).toList(),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comment input
              if (userProfile != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SafeArea(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.teal.shade100,
                          backgroundImage: userProfile.avatarUrl != null
                              ? NetworkImage(userProfile.avatarUrl!)
                              : null,
                          child: userProfile.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.teal.shade700,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _addComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addComment,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showPostMenu(BuildContext context, CommunityPost post) {
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
                      // Refresh the post
                      setState(() {});
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
                      if (context.mounted) {
                        Navigator.of(context).pop();
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

class _CommentCard extends StatelessWidget {
  final PostComment comment;
  final VoidCallback? onDelete;

  const _CommentCard({required this.comment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal.shade100,
            backgroundImage: comment.userAvatarUrl != null
                ? NetworkImage(comment.userAvatarUrl!)
                : null,
            child: comment.userAvatarUrl == null
                ? Icon(Icons.person, size: 16, color: Colors.teal.shade700)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userDisplayName ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  timeago.format(comment.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
