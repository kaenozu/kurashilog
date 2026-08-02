import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/places/places_screen.dart';
import '../features/settings/settings_screen.dart';

/// メインシェル（設計書 7.1 ナビゲーション）。
///
/// ホーム / カレンダー / 地点 / 設定 の 4 タブ。
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(appTabProvider);

    final screens = [
      const HomeScreen(),
      const CalendarScreen(),
      const PlacesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: tab, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) =>
            ref.read(appTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'カレンダー',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: '地点',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
