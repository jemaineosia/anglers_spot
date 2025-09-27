// lib/features/main/view/main_page.dart
import 'package:anglers_spot/features/catch_log/view/catch_log_list.dart';
import 'package:anglers_spot/features/plan/view/planner_screen.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final _pages = const [PlannerScreen(), CatchLogListPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Plan"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Catch Log"),
        ],
      ),
    );
  }
}
