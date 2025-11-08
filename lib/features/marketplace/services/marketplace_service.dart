import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_item.dart';

class MarketplaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all marketplace items
  Future<List<MarketplaceItem>> getItems({
    bool? showSold,
    String? category,
    int limit = 50,
  }) async {
    var query = _supabase.from('marketplace_items').select('*');

    if (showSold != null) {
      query = query.eq('is_sold', showSold);
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    final items = response as List;
    final userIds = items.map((i) => i['user_id'] as String).toSet().toList();

    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, display_name, avatar_url')
        .inFilter('id', userIds);

    final profilesMap = {
      for (var profile in profilesResponse as List)
        profile['id'] as String: profile,
    };

    return items.map((json) {
      final profile = profilesMap[json['user_id'] as String];
      return MarketplaceItem.fromJson({
        ...json,
        'user_display_name': profile?['display_name'],
        'user_avatar_url': profile?['avatar_url'],
      });
    }).toList();
  }

  /// Get items with real-time updates
  Stream<List<MarketplaceItem>> getItemsStream({
    bool? showSold,
    int limit = 50,
  }) {
    var stream = _supabase
        .from('marketplace_items')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    if (limit > 0) {
      stream = stream.limit(limit);
    }

    return stream.asyncMap((items) async {
      if (items.isEmpty) return <MarketplaceItem>[];

      // Filter by sold status if specified
      var filteredItems = items;
      if (showSold != null) {
        filteredItems = items
            .where((item) => item['is_sold'] == showSold)
            .toList();
      }

      if (filteredItems.isEmpty) return <MarketplaceItem>[];

      final userIds = filteredItems
          .map((i) => i['user_id'] as String)
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

      return filteredItems.map((json) {
        final profile = profilesMap[json['user_id'] as String];
        return MarketplaceItem.fromJson({
          ...json,
          'user_display_name': profile?['display_name'],
          'user_avatar_url': profile?['avatar_url'],
        });
      }).toList();
    });
  }

  /// Get a single item
  Future<MarketplaceItem> getItem(String itemId) async {
    final response = await _supabase
        .from('marketplace_items')
        .select('*')
        .eq('id', itemId)
        .single();

    final userId = response['user_id'] as String;
    final profileResponse = await _supabase
        .from('profiles')
        .select('id, display_name, avatar_url')
        .eq('id', userId)
        .single();

    return MarketplaceItem.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Create a new item
  Future<MarketplaceItem> createItem({
    required String title,
    required String description,
    required double price,
    String? category,
    String? condition,
    String? location,
    List<String>? imageUrls,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('marketplace_items')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'price': price,
          'category': category,
          'condition': condition,
          'location': location,
          'image_urls': imageUrls,
        })
        .select()
        .single();

    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return MarketplaceItem.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Update an item
  Future<MarketplaceItem> updateItem({
    required String itemId,
    required String title,
    required String description,
    required double price,
    String? category,
    String? condition,
    String? location,
    List<String>? imageUrls,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('marketplace_items')
        .update({
          'title': title,
          'description': description,
          'price': price,
          'category': category,
          'condition': condition,
          'location': location,
          'image_urls': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId)
        .select()
        .single();

    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return MarketplaceItem.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Mark item as sold/unsold
  Future<void> toggleSoldStatus(String itemId, bool isSold) async {
    await _supabase
        .from('marketplace_items')
        .update({
          'is_sold': isSold,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _supabase.from('marketplace_items').delete().eq('id', itemId);
  }

  /// Get user's items
  Future<List<MarketplaceItem>> getUserItems(String userId) async {
    final response = await _supabase
        .from('marketplace_items')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return (response as List).map((json) {
      return MarketplaceItem.fromJson({
        ...json,
        'user_display_name': profileResponse['display_name'],
        'user_avatar_url': profileResponse['avatar_url'],
      });
    }).toList();
  }
}
