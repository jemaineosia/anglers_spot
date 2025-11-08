import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;

  // Get user count
  final usersResponse = await supabase
      .from('profiles')
      .select('*')
      .count(CountOption.exact);
  final userCount = usersResponse.count;

  // Get marketplace items count
  final itemsResponse = await supabase
      .from('marketplace_items')
      .select('*')
      .count(CountOption.exact);
  final itemsCount = itemsResponse.count;

  // Get chat channels count
  final channelsResponse = await supabase
      .from('chat_channels')
      .select('*')
      .eq('is_active', true)
      .count(CountOption.exact);
  final channelsCount = channelsResponse.count;

  // Get chat messages count
  final messagesResponse = await supabase
      .from('chat_messages')
      .select('*')
      .count(CountOption.exact);
  final messagesCount = messagesResponse.count;

  // Get catches count
  final catchesResponse = await supabase
      .from('catches')
      .select('*')
      .count(CountOption.exact);
  final catchesCount = catchesResponse.count;

  return {
    'users': userCount,
    'items': itemsCount,
    'channels': channelsCount,
    'messages': messagesCount,
    'catches': catchesCount,
  };
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final canView = userProfile?.role.canModerate ?? false;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to view analytics'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(analyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
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
                onPressed: () => ref.invalidate(analyticsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (analytics) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Platform Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: LucideIcons.users,
                    label: 'Total Users',
                    value: analytics['users'].toString(),
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: LucideIcons.shoppingBag,
                    label: 'Marketplace Items',
                    value: analytics['items'].toString(),
                    color: Colors.orange,
                  ),
                  _StatCard(
                    icon: LucideIcons.messageCircle,
                    label: 'Chat Channels',
                    value: analytics['channels'].toString(),
                    color: Colors.teal,
                  ),
                  _StatCard(
                    icon: LucideIcons.send,
                    label: 'Messages',
                    value: analytics['messages'].toString(),
                    color: Colors.purple,
                  ),
                  _StatCard(
                    icon: LucideIcons.fish,
                    label: 'Catches Logged',
                    value: analytics['catches'].toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
