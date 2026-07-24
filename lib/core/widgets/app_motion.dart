import 'package:flutter/material.dart';

class AppMotion {
	static const Curve curve = Curves.easeOutCubic;
	static const Duration shortDuration = Duration(milliseconds: 200);
	static const Duration duration = Duration(milliseconds: 240);
	static const Duration routeDuration = Duration(milliseconds: 260);
	static const Duration reverseRouteDuration = Duration(milliseconds: 220);
	static const Offset subtleOffset = Offset(0, 0.02);
}

class FadeSlideIn extends StatelessWidget {
	const FadeSlideIn({
		super.key,
		required this.child,
		this.duration = AppMotion.duration,
		this.curve = AppMotion.curve,
		this.beginOffset = AppMotion.subtleOffset,
	});

	final Widget child;
	final Duration duration;
	final Curve curve;
	final Offset beginOffset;

	@override
	Widget build(BuildContext context) {
		return TweenAnimationBuilder<double>(
			tween: Tween<double>(begin: 0, end: 1),
			duration: duration,
			curve: curve,
			builder: (context, value, child) {
				return Opacity(
					opacity: value,
					child: Transform.translate(
						offset: Offset(
							beginOffset.dx * (1 - value) * 100,
							beginOffset.dy * (1 - value) * 100,
						),
						child: child,
					),
				);
			},
			child: child,
		);
	}
}