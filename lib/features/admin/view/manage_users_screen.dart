import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

final usersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', ascending: false);

  return (response as List).map((json) => UserProfile.fromJson(json)).toList();
});

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(userProfileProvider).value;
    final isAdmin = currentUser?.role.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Only administrators can manage users')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Users list
          Expanded(
            child: usersAsync.when(
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
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(usersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                final filteredUsers = _searchQuery.isEmpty
                    ? users
                    : users
                          .where(
                            (user) =>
                                (user.displayName ?? '').toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                (user.email ?? '').toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isCurrentUser = user.id == currentUser?.id;

                    return _UserCard(
                      user: user,
                      isCurrentUser: isCurrentUser,
                      onRoleChanged: () => ref.invalidate(usersProvider),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserProfile user;
  final bool isCurrentUser;
  final VoidCallback onRoleChanged;

  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(LucideIcons.user)
                  : null,
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _RoleBadge(role: user.role),
                ],
              ),
            ),

            // Actions
            if (!isCurrentUser)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'change_role') {
                    await _showRoleDialog(context, ref, user);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(LucideIcons.userCog, size: 18),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoleDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) async {
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change role for ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('User'),
              subtitle: const Text('Regular user access'),
              value: 'user',
              groupValue: user.role.name,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Moderator'),
              subtitle: const Text('Can moderate content and create channels'),
              value: 'moderator',
              groupValue: user.role.name,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Admin'),
              subtitle: const Text('Full administrative access'),
              value: 'admin',
              groupValue: user.role.name,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedRole != null && context.mounted) {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('profiles')
            .update({'role': selectedRole})
            .eq('id', user.id);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User role updated')));
          onRoleChanged();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (role) {
      case UserRole.admin:
        color = Colors.purple;
        icon = LucideIcons.shield;
        label = 'Admin';
        break;
      case UserRole.moderator:
        color = Colors.blue;
        icon = LucideIcons.shieldCheck;
        label = 'Moderator';
        break;
      case UserRole.user:
        color = Colors.grey;
        icon = LucideIcons.user;
        label = 'User';
        break;
      case UserRole.anonymous:
        color = Colors.grey;
        icon = LucideIcons.userX;
        label = 'Anonymous';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
