import 'package:flutter/material.dart';

import 'package:nuvora/features/home/presentation/screens/home_screen.dart';
import 'package:nuvora/features/insights/presentation/screens/insights_screen.dart';
import 'package:nuvora/features/notes/presentation/screens/notes_screen.dart';
import 'package:nuvora/features/settings/presentation/screens/settings_screen.dart';
import 'package:nuvora/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:nuvora/core/widgets/app_navigation_bar.dart';
import 'package:nuvora/core/widgets/shell_container.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class MainShell extends AppShell {
  const MainShell({super.key});
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 1;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const TasksScreen(),
      const NotesScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ShellContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Column(
          children: [
            Expanded(
              child: _AnimatedViewport(
                selectedIndex: _selectedIndex,
                child: IndexedStack(
                  index: _selectedIndex,
                  children: List.generate(_screens.length, (index) {
                    return HeroMode(
                      enabled: index == _selectedIndex,
                      child: TickerMode(
                        enabled: index == _selectedIndex,
                        child: _screens[index],
                      ),
                    );
                  }),
                ),
              ),
            ),
            AppNavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
					if (index == _selectedIndex) return;
					setState(() => _selectedIndex = index);
              },
              destinations: const [
                AppNavigationDestination(
                  icon: Icons.home_outlined,
                  label: 'Home',
                ),
                AppNavigationDestination(
                  icon: Icons.check_circle_outline,
                  label: 'Tasks',
                ),
                AppNavigationDestination(
                  icon: Icons.note_outlined,
                  label: 'Notes',
                ),
                AppNavigationDestination(
                  icon: Icons.insights_outlined,
                  label: 'Insights',
                ),
                AppNavigationDestination(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedViewport extends StatelessWidget {
  const _AnimatedViewport({
    required this.selectedIndex,
    required this.child,
  });

  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(selectedIndex),
      tween: Tween<double>(begin: 0.975, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.88 + (value - 0.975) * 4.8,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: Transform.scale(
              scale: value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
