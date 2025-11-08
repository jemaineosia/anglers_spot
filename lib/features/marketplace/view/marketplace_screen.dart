import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/providers/auth_provider.dart';
import '../models/marketplace_item.dart';
import '../providers/marketplace_provider.dart';
import 'create_item_screen.dart';
import 'item_detail_screen.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(marketplaceItemsStreamProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final canPost = userProfile?.role.canPost ?? false;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketplaceItemsStreamProvider);
        },
        child: itemsAsync.when(
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
                  onPressed: () =>
                      ref.invalidate(marketplaceItemsStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.shoppingBag,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to list something!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (canPost) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateItemScreen(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.plus),
                        label: const Text('List Item'),
                      ),
                    ],
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(item: items[index]);
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
                        builder: (_) => const CreateItemScreen(),
                      ),
                    )
                    .then(
                      (_) => ref.invalidate(marketplaceItemsStreamProvider),
                    );
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }
}

class ItemCard extends StatelessWidget {
  final MarketplaceItem item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: item.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade200,
                child: item.imageUrls != null && item.imageUrls!.isNotEmpty
                    ? Image.network(
                        item.imageUrls!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            LucideIcons.image,
                            size: 48,
                            color: Colors.grey.shade400,
                          );
                        },
                      )
                    : Icon(
                        LucideIcons.image,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          timeago.format(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
