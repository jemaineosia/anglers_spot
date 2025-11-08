// lib/features/main/view/main_page.dart
import 'package:anglers_spot/features/catch_log/view/catch_log_list.dart';
import 'package:anglers_spot/features/chat/view/chat_list_screen.dart';
import 'package:anglers_spot/features/marketplace/view/marketplace_screen.dart';
import 'package:anglers_spot/features/plan/view/planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final _pages = const [
    ChatListScreen(),
    MarketplaceScreen(),
    CatchLogListPage(),
    PlannerScreen(),
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
}
