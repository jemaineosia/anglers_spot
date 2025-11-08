import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_channel.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Stream-based provider for real-time channel updates
final chatChannelsStreamProvider =
    StreamProvider.autoDispose<List<ChatChannel>>((ref) {
      final service = ref.watch(chatServiceProvider);
      return service.getChannelsStream();
    });

/// Stream-based provider for real-time message updates in a channel
final chatMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, channelId) {
      final service = ref.watch(chatServiceProvider);
      return service.getMessagesStream(channelId);
    });
