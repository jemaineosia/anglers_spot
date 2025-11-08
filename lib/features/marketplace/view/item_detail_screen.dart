import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/providers/auth_provider.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/view/chat_conversation_screen.dart';
import '../models/marketplace_item.dart';
import '../providers/marketplace_provider.dart';
import 'edit_item_screen.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: FutureBuilder<MarketplaceItem>(
        future: ref.read(marketplaceServiceProvider).getItem(widget.itemId),
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

          final item = snapshot.data!;
          final userProfile = ref.watch(userProfileProvider).value;
          final isOwnItem = userProfile?.id == item.userId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images
                if (item.imageUrls != null && item.imageUrls!.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: item.imageUrls!.length == 1
                        ? Image.network(
                            item.imageUrls!.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : PageView.builder(
                            itemCount: item.imageUrls!.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                item.imageUrls![index],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  )
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Icon(
                      LucideIcons.image,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sold badge
                      if (item.isSold)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (item.isSold) const SizedBox(height: 16),

                      // Title and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isOwnItem ||
                              (userProfile?.role.canModerate ?? false))
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showItemMenu(context, item),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Seller info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.teal.shade100,
                            backgroundImage: item.userAvatarUrl != null
                                ? NetworkImage(item.userAvatarUrl!)
                                : null,
                            child: item.userAvatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    color: Colors.teal.shade700,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Seller',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  item.userDisplayName ?? 'Unknown User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isOwnItem && !item.isSold)
                            FilledButton.icon(
                              onPressed: () => _messageSeller(context, item),
                              icon: const Icon(
                                LucideIcons.messageCircle,
                                size: 18,
                              ),
                              label: const Text('Message'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Details
                      if (item.condition != null) ...[
                        _buildDetailRow('Condition', item.condition!),
                        const SizedBox(height: 8),
                      ],
                      if (item.category != null) ...[
                        _buildDetailRow('Category', item.category!),
                        const SizedBox(height: 8),
                      ],
                      if (item.location != null) ...[
                        _buildDetailRow('Location', item.location!),
                        const SizedBox(height: 8),
                      ],
                      _buildDetailRow('Posted', timeago.format(item.createdAt)),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 16),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _messageSeller(BuildContext context, MarketplaceItem item) async {
    // Show loading indicator
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Creating chat...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Create or get DM channel with seller
      final chatService = ChatService();
      final channel = await chatService.getOrCreateDMChannel(
        otherUserId: item.userId,
        itemTitle: item.title,
      );

      if (context.mounted) {
        // Navigate to chat conversation
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(channel: channel),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error creating chat: $e')),
        );
      }
    }
  }

  void _showItemMenu(BuildContext context, MarketplaceItem item) {
    final userProfile = ref.read(userProfileProvider).value;
    final isOwnItem = userProfile?.id == item.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mark as sold/available (only for own items)
              if (isOwnItem)
                ListTile(
                  leading: Icon(
                    item.isSold ? LucideIcons.rotateCcw : LucideIcons.check,
                  ),
                  title: Text(
                    item.isSold ? 'Mark as Available' : 'Mark as Sold',
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final service = ref.read(marketplaceServiceProvider);
                      await service.toggleSoldStatus(item.id, !item.isSold);
                      if (context.mounted) {
                        setState(() {}); // Refresh the screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              item.isSold
                                  ? 'Item marked as available'
                                  : 'Item marked as sold',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              // Edit option (only for own items)
              if (isOwnItem)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Item'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditItemScreen(item: item),
                      ),
                    );
                    if (result == true && context.mounted) {
                      setState(() {}); // Refresh the screen
                    }
                  },
                ),
              // Delete option
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Item',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Item'),
                      content: const Text(
                        'Are you sure you want to delete this item?',
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
                      final service = ref.read(marketplaceServiceProvider);
                      await service.deleteItem(item.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
