import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/providers/auth_provider.dart';
import 'analytics_screen.dart';
import 'manage_channels_screen.dart';
import 'manage_marketplace_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final isAdmin = userProfile?.role.isAdmin ?? false;
    final isModerator = userProfile?.role.canModerate ?? false;

    if (!isAdmin && !isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'You do not have permission to access this page',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'Moderator Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User role badge
          Card(
            color: isAdmin ? Colors.purple.shade50 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isAdmin ? LucideIcons.shield : LucideIcons.shieldCheck,
                    color: isAdmin ? Colors.purple : Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Administrator' : 'Moderator',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile?.displayName ?? 'User',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Management sections
          Text(
            'Management',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Marketplace moderation
          _DashboardCard(
            icon: LucideIcons.shoppingBag,
            title: 'Manage Marketplace',
            subtitle: 'Review and moderate marketplace listings',
            color: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManageMarketplaceScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Chat channels management (admin only)
          if (isAdmin)
            _DashboardCard(
              icon: LucideIcons.messageSquare,
              title: 'Manage Channels',
              subtitle: 'View, edit, and moderate chat channels',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageChannelsScreen(),
                  ),
                );
              },
            ),
          if (isAdmin) const SizedBox(height: 12),

          // User management (admin only)
          if (isAdmin)
            _DashboardCard(
              icon: LucideIcons.users,
              title: 'Manage Users',
              subtitle: 'View users, manage roles, and handle bans',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                );
              },
            ),
          if (isAdmin) const SizedBox(height: 12),

          // Analytics
          _DashboardCard(
            icon: LucideIcons.barChart3,
            title: 'Analytics',
            subtitle: 'View platform statistics and insights',
            color: Colors.green,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
