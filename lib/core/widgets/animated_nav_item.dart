import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_colors.dart';
import 'package:nuvora/core/theme/app_radius.dart';
import 'package:nuvora/core/theme/app_spacing.dart';
import 'package:nuvora/core/widgets/app_motion.dart';

class AnimatedNavItem extends StatelessWidget {
  const AnimatedNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
    final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      selected: selected,
      label: '$label tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          canRequestFocus: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedContainer(
              duration: motionDuration,
              curve: motionCurve,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: motionDuration,
                    scale: selected ? 1.06 : 1.0,
                    curve: motionCurve,
                    child: AnimatedContainer(
                      duration: motionDuration,
                      curve: motionCurve,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary.withValues(alpha: 0.16) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: selected ? 23 : 21,
                        color: selected ? scheme.primary : theme.iconTheme.color?.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: motionDuration,
                    curve: motionCurve,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: selected ? scheme.primary : AppColors.darkOnSurface.withValues(alpha: 0.74),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
