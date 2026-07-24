import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_colors.dart';
import 'package:nuvora/core/theme/app_radius.dart';
import 'package:nuvora/core/theme/app_spacing.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';
import 'package:nuvora/core/widgets/animated_nav_item.dart';

class AppNavigationDestination {
  const AppNavigationDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontalPadding = AppResponsive.pagePadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final destination = destinations[index];
              return Expanded(
                child: AnimatedNavItem(
                  icon: destination.icon,
                  label: destination.label,
                  selected: index == selectedIndex,
                  onTap: () => onDestinationSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
