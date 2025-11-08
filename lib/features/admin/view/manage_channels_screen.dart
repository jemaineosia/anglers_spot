import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../chat/models/chat_channel.dart';
import '../../chat/providers/chat_provider.dart';

/// Provider to get ALL channels including inactive ones (admin view)
final allChannelsStreamProvider = StreamProvider.autoDispose<List<ChatChannel>>(
  (ref) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.getAllChannelsStream();
  },
);

class ManageChannelsScreen extends ConsumerStatefulWidget {
  const ManageChannelsScreen({super.key});

  @override
  ConsumerState<ManageChannelsScreen> createState() =>
      _ManageChannelsScreenState();
}

class _ManageChannelsScreenState extends ConsumerState<ManageChannelsScreen> {
  String _searchQuery = '';
  bool _showInactiveOnly = false;

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(allChannelsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Channels'),
        actions: [
          IconButton(
            icon: Icon(_showInactiveOnly ? Icons.toggle_on : Icons.toggle_off),
            tooltip: _showInactiveOnly ? 'Show All' : 'Show Inactive Only',
            onPressed: () {
              setState(() => _showInactiveOnly = !_showInactiveOnly);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Channels list
          Expanded(
            child: channelsAsync.when(
              data: (channels) {
                var filteredChannels = channels.where((channel) {
                  final matchesSearch =
                      channel.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (channel.description?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ??
                          false);

                  final matchesActiveFilter = _showInactiveOnly
                      ? !channel.isActive
                      : true; // Show all if not filtering

                  return matchesSearch && matchesActiveFilter;
                }).toList();

                if (filteredChannels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.messageSquare,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No channels found'
                              : 'No channels yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allChannelsStreamProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredChannels.length,
                    itemBuilder: (context, index) {
                      final channel = filteredChannels[index];
                      return _ChannelCard(
                        channel: channel,
                        onEdit: () => _showEditChannelDialog(channel),
                        onToggleActive: () => _toggleChannelActive(channel),
                        onDelete: () => _showDeleteConfirmation(channel),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(allChannelsStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditChannelDialog(ChatChannel channel) async {
    final nameController = TextEditingController(text: channel.name);
    final descriptionController = TextEditingController(
      text: channel.description,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final chatService = ref.read(chatServiceProvider);
        await chatService.updateChannel(
          channelId: channel.id,
          name: nameController.text,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Channel updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating channel: $e')));
        }
      }
    }
  }

  Future<void> _toggleChannelActive(ChatChannel channel) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.toggleChannelActive(channel.id, !channel.isActive);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              channel.isActive ? 'Channel deactivated' : 'Channel reactivated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling channel: $e')));
      }
    }
  }

  Future<void> _showDeleteConfirmation(ChatChannel channel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Channel'),
        content: Text(
          'Are you sure you want to permanently delete "${channel.name}"? '
          'This will also delete all messages in this channel. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final chatService = ref.read(chatServiceProvider);
        await chatService.deleteChannel(channel.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Channel deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting channel: $e')));
        }
      }
    }
  }
}

class _ChannelCard extends StatelessWidget {
  final ChatChannel channel;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ChannelCard({
    required this.channel,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  bool get _isDMChannel => channel.name.startsWith('DM: ');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Channel icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: channel.isActive
                        ? Colors.teal.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isDMChannel ? LucideIcons.messageCircle : LucideIcons.hash,
                    color: channel.isActive ? Colors.teal : Colors.grey,
                    size: 20,
                  ),
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
                              channel.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!channel.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (channel.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          channel.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.users, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${channel.memberCount} members',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(channel.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button (not for DM channels)
                if (!_isDMChannel)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                const SizedBox(width: 8),
                // Toggle active button
                TextButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    channel.isActive ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 16,
                  ),
                  label: Text(channel.isActive ? 'Deactivate' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor: channel.isActive
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}
