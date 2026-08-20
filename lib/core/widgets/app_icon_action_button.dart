import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';

class AppIconActionButton extends StatelessWidget {
	const AppIconActionButton({
		super.key,
		required this.icon,
		required this.label,
		required this.onPressed,
		this.color = AppColors.textSecondary,
	});

	final IconData icon;
	final String label;
	final VoidCallback? onPressed;
	final Color color;

	@override
	Widget build(BuildContext context) {
		return Semantics(
			button: true,
			enabled: onPressed != null,
			label: label,
			child: IconButton(
				onPressed: onPressed,
				tooltip: label,
				icon: Icon(icon),
				color: color,
				iconSize: 20,
				padding: const EdgeInsets.all(AppSpacing.sm),
				constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
			),
		);
	}
}