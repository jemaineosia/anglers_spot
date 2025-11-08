import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_channel.dart';
import '../models/chat_message.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============= CHANNELS =============

  /// Get all active chat channels
  Future<List<ChatChannel>> getChannels() async {
    final response = await _supabase
        .from('chat_channels')
        .select('*')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ChatChannel.fromJson(json))
        .toList();
  }

  /// Get channels with real-time updates
  Stream<List<ChatChannel>> getChannelsStream() {
    return _supabase
        .from('chat_channels')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .map((channels) {
          return channels.map((json) => ChatChannel.fromJson(json)).toList();
        });
  }

  /// Create a new channel (admin/moderator only)
  Future<ChatChannel> createChannel({
    required String name,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('chat_channels')
        .insert({
          'name': name,
          'description': description,
          'created_by': userId,
        })
        .select()
        .single();

    return ChatChannel.fromJson(response);
  }

  /// Get a single channel
  Future<ChatChannel> getChannel(String channelId) async {
    final response = await _supabase
        .from('chat_channels')
        .select('*')
        .eq('id', channelId)
        .single();

    return ChatChannel.fromJson(response);
  }

  /// Get all channels including inactive (admin only)
  Stream<List<ChatChannel>> getAllChannelsStream() {
    return _supabase
        .from('chat_channels')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((channels) {
          return channels.map((json) => ChatChannel.fromJson(json)).toList();
        });
  }

  /// Update channel details (admin only)
  Future<void> updateChannel({
    required String channelId,
    required String name,
    String? description,
  }) async {
    await _supabase
        .from('chat_channels')
        .update({'name': name, 'description': description})
        .eq('id', channelId);
  }

  /// Toggle channel active status (admin only)
  Future<void> toggleChannelActive(String channelId, bool isActive) async {
    await _supabase
        .from('chat_channels')
        .update({'is_active': isActive})
        .eq('id', channelId);
  }

  /// Delete channel and all its messages (admin only)
  Future<void> deleteChannel(String channelId) async {
    // Delete all messages in the channel first
    await _supabase.from('chat_messages').delete().eq('channel_id', channelId);

    // Then delete the channel
    await _supabase.from('chat_channels').delete().eq('id', channelId);
  }

  // ============= MESSAGES =============

  /// Get messages for a channel
  Future<List<ChatMessage>> getMessages(
    String channelId, {
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('chat_messages')
        .select('*')
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = response as List;
    final userIds = messages
        .map((m) => m['user_id'] as String)
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

    return messages
        .map((json) {
          final profile = profilesMap[json['user_id'] as String];
          return ChatMessage.fromJson({
            ...json,
            'user_display_name': profile?['display_name'],
            'user_avatar_url': profile?['avatar_url'],
          });
        })
        .toList()
        .reversed
        .toList(); // Reverse to show oldest first
  }

  /// Get messages with real-time updates
  Stream<List<ChatMessage>> getMessagesStream(String channelId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .asyncMap((messages) async {
          if (messages.isEmpty) return <ChatMessage>[];

          final userIds = messages
              .map((m) => m['user_id'] as String)
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

          return messages.map((json) {
            final profile = profilesMap[json['user_id'] as String];
            return ChatMessage.fromJson({
              ...json,
              'user_display_name': profile?['display_name'],
              'user_avatar_url': profile?['avatar_url'],
            });
          }).toList();
        });
  }

  /// Send a message
  Future<ChatMessage> sendMessage({
    required String channelId,
    required String content,
    String? mediaUrl,
    String? replyTo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('chat_messages')
        .insert({
          'channel_id': channelId,
          'user_id': userId,
          'content': content,
          'media_url': mediaUrl,
          'reply_to': replyTo,
        })
        .select()
        .single();

    // Fetch user profile
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return ChatMessage.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Update a message
  Future<ChatMessage> updateMessage({
    required String messageId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('chat_messages')
        .update({
          'content': content,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId)
        .select()
        .single();

    // Fetch user profile
    final profileResponse = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .single();

    return ChatMessage.fromJson({
      ...response,
      'user_display_name': profileResponse['display_name'],
      'user_avatar_url': profileResponse['avatar_url'],
    });
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('chat_messages').delete().eq('id', messageId);
  }

  /// Get or create a direct message channel between two users
  Future<ChatChannel> getOrCreateDMChannel({
    required String otherUserId,
    String? itemTitle,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if DM channel already exists
    // DM channels are named with pattern "DM: user1_user2" where user1 < user2
    final userIds = [userId, otherUserId]..sort();
    final dmChannelName = 'DM: ${userIds[0]}_${userIds[1]}';

    try {
      final existingChannel = await _supabase
          .from('chat_channels')
          .select('*')
          .eq('name', dmChannelName)
          .eq('is_active', true)
          .single();

      return ChatChannel.fromJson(existingChannel);
    } catch (e) {
      // Channel doesn't exist, create it
      final description = itemTitle != null
          ? 'Marketplace inquiry about: $itemTitle'
          : 'Direct message';

      return await createChannel(name: dmChannelName, description: description);
    }
  }
}
