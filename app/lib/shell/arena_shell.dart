import 'package:flutter/material.dart';

import '../account/ui/leaderboard_tab.dart';
import '../account/ui/profile_tab.dart';
import '../battle/ui/battle_tab.dart';

/// The three contract tabs, left to right. Battle is the default.
enum ArenaTab {
  leaderboard(
    label: 'Leaderboard',
    icon: Icons.leaderboard_outlined,
    selectedIcon: Icons.leaderboard,
    description: 'Ranked ladder arrives with task 06.',
  ),
  battle(
    label: 'Battle',
    icon: Icons.sports_martial_arts_outlined,
    selectedIcon: Icons.sports_martial_arts,
    description: 'Camera-counted 60-second battles arrive with task 07.',
  ),
  profile(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    description: 'Sign-in, username and history arrive with task 06.',
  );

  const ArenaTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String description;
}

/// Bottom-navigation shell: Leaderboard, Battle (default), Profile.
///
/// Task 06 replaces the Leaderboard/Profile bodies and task 07 replaces
/// the Battle body; the tab order and default index are contract.
class ArenaShell extends StatefulWidget {
  const ArenaShell({super.key});

  @override
  State<ArenaShell> createState() => _ArenaShellState();
}

class _ArenaShellState extends State<ArenaShell> {
  int _selectedIndex = ArenaTab.battle.index;

  @override
  Widget build(BuildContext context) {
    final selectedTab = ArenaTab.values[_selectedIndex];
    return Scaffold(
      key: const ValueKey('arena-shell'),
      body: SafeArea(
        child: switch (selectedTab) {
          ArenaTab.battle =>
            const BattleTab(key: ValueKey('arena-page-battle')),
          ArenaTab.leaderboard =>
            const LeaderboardTab(key: ValueKey('arena-page-leaderboard')),
          ArenaTab.profile =>
            const ProfileTab(key: ValueKey('arena-page-profile')),
        },
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('arena-bottom-nav'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final tab in ArenaTab.values)
            NavigationDestination(
              key: ValueKey('arena-tab-${tab.name}'),
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
