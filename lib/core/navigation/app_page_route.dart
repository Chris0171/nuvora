import 'package:flutter/material.dart';
import 'package:nuvora/core/widgets/app_motion.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    Duration duration = AppMotion.routeDuration,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: AppMotion.reverseRouteDuration,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: AppMotion.curve,
              reverseCurve: AppMotion.curve,
            );
            final offsetAnimation = Tween<Offset>(
              begin: AppMotion.subtleOffset,
              end: Offset.zero,
            ).animate(curvedAnimation);
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        );
}
