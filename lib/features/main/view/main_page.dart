// lib/features/main/view/main_page.dart
import 'package:anglers_spot/features/catch_log/view/catch_log_list.dart';
import 'package:anglers_spot/features/chat/view/chat_list_screen.dart';
import 'package:anglers_spot/features/marketplace/view/marketplace_screen.dart';
import 'package:anglers_spot/features/plan/view/planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/providers/auth_provider.dart';
import '../../profile/view/profile_screen.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

  final _pages = const [
    ChatListScreen(),
    MarketplaceScreen(),
    CatchLogListPage(),
    PlannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: _getPageTitle(),
        actions: [
          // Profile avatar button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundImage: userProfile?.avatarUrl != null
                    ? NetworkImage(userProfile!.avatarUrl!)
                    : null,
                child: userProfile?.avatarUrl == null
                    ? const Icon(LucideIcons.user, size: 18)
                    : null,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              tooltip: 'Profile',
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.messageCircle),
            label: "Chat",
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.shoppingBag),
            label: "Marketplace",
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.fish),
            label: "Catch Report",
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.cloudSun),
            label: "Forecast",
          ),
        ],
      ),
    );
  }

  Widget _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return const Text('Chat');
      case 1:
        return const Text('Marketplace');
      case 2:
        return const Text('Catch Report');
      case 3:
        return const Text('Weather Forecast');
      default:
        return const Text('Angler\'s Spot');
    }
  }
}
