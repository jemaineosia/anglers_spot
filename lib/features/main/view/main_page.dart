// lib/features/main/view/main_page.dart
import 'package:anglers_spot/features/catch_log/view/catch_log_list.dart';
import 'package:anglers_spot/features/plan/view/planner_screen.dart';
import 'package:anglers_spot/features/profile/view/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // TODO: Replace placeholders with actual screens
  final _pages = const [
    _PlaceholderScreen(title: 'Chat', icon: LucideIcons.messageCircle),
    _PlaceholderScreen(title: 'Community', icon: LucideIcons.users),
    CatchLogListPage(),
    PlannerScreen(), // Renamed from "Plan" to "Forecast"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(LucideIcons.users),
            label: "Community",
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.fish),
            label: "Catch Log",
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.cloudSun),
            label: "Forecast",
          ),
        ],
      ),
    );
  }
}

// Placeholder screen for features not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              '$title Feature',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
