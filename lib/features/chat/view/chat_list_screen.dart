import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/providers/auth_provider.dart';
import '../models/chat_channel.dart';
import '../providers/chat_provider.dart';
import 'chat_conversation_screen.dart';
import 'create_channel_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(chatChannelsStreamProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final canCreateChannel = userProfile?.role.isAdmin ?? false;

    return Scaffold(
      floatingActionButton: canCreateChannel
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateChannelScreen(),
                  ),
                );
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: channelsAsync.when(
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
                onPressed: () => ref.invalidate(chatChannelsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (channels) {
          if (channels.isEmpty) {
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
                    'No chat channels yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canCreateChannel
                        ? 'Create a channel to get started'
                        : 'Check back later for active channels',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (canCreateChannel) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateChannelScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Create Channel'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return ChannelCard(channel: channels[index]);
            },
          );
        },
      ),
    );
  }
}

class ChannelCard extends StatelessWidget {
  final ChatChannel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Icon(LucideIcons.hash, color: Colors.teal.shade700),
        ),
        title: Text(
          channel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (channel.description != null) ...[
              const SizedBox(height: 4),
              Text(
                channel.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (channel.lastMessageAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(channel.lastMessageAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (channel.memberCount > 0) ...[
              Icon(LucideIcons.users, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${channel.memberCount}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(channel: channel),
            ),
          );
        },
      ),
    );
  }
}
