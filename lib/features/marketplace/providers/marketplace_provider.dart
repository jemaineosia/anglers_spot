import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';

final marketplaceServiceProvider = Provider<MarketplaceService>((ref) {
  return MarketplaceService();
});

/// Stream-based provider for real-time marketplace items
/// Automatically updates when:
/// - New items are created
/// - Items are updated or deleted
/// - Items are marked as sold
final marketplaceItemsStreamProvider =
    StreamProvider.autoDispose<List<MarketplaceItem>>((ref) {
      final service = ref.watch(marketplaceServiceProvider);
      return service.getItemsStream(
        showSold: false,
      ); // Only show available items by default
    });

/// Stream-based provider for all items including sold
final allMarketplaceItemsStreamProvider =
    StreamProvider.autoDispose<List<MarketplaceItem>>((ref) {
      final service = ref.watch(marketplaceServiceProvider);
      return service.getItemsStream(); // Show all items
    });
