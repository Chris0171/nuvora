import 'package:flutter/material.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';

class AppFeedback {
	static void showSnackBar(BuildContext context, String message) {
		final messenger = ScaffoldMessenger.of(context);
		final horizontalPadding = AppResponsive.pagePadding(context);
		messenger.hideCurrentSnackBar();
		messenger.showSnackBar(
			SnackBar(
				content: Text(message),
				behavior: SnackBarBehavior.floating,
				duration: const Duration(seconds: 2),
				elevation: 0,
				margin: EdgeInsets.fromLTRB(
					horizontalPadding,
					0,
					horizontalPadding,
					AppSpacing.lg,
				),
				padding: const EdgeInsets.symmetric(
					horizontal: AppSpacing.lg,
					vertical: AppSpacing.md,
				),
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(AppRadius.xl),
					side: const BorderSide(color: AppColors.border),
				),
			),
		);
	}
}

class AppLoadingState extends StatelessWidget {
	const AppLoadingState({super.key, required this.label});

	final String label;

	@override
	Widget build(BuildContext context) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final maxWidth = AppResponsive.maxContentWidth(context);
		return Center(
			child: ConstrainedBox(
				constraints: BoxConstraints(maxWidth: maxWidth),
				child: Padding(
					padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							const SizedBox(height: 60),
							AnimatedContainer(
								duration: AppMotion.duration,
								curve: AppMotion.curve,
								width: 72,
								height: 72,
								decoration: BoxDecoration(
									color: AppColors.surface,
									border: Border.all(color: AppColors.border),
									borderRadius: BorderRadius.circular(AppRadius.xl),
								),
								child: const Center(
									child: CircularProgressIndicator(color: AppColors.primary),
								),
							),
							const SizedBox(height: AppSpacing.lg),
							Text(
								label,
								style: AppTypography.bodyMedium.copyWith(
									color: AppColors.textSecondary,
								),
							),
							const SizedBox(height: 60),
						],
					),
				),
			),
		);
	}
}

class AppEmptyState extends StatelessWidget {
	const AppEmptyState({
		super.key,
		required this.icon,
		required this.title,
		required this.description,
		this.detail,
		this.button,
	});

	final IconData icon;
	final String title;
	final String description;
	final String? detail;
	final Widget? button;

	@override
	Widget build(BuildContext context) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final maxWidth = AppResponsive.maxContentWidth(context);
		return Padding(
			padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
			child: Center(
				child: ConstrainedBox(
					constraints: BoxConstraints(maxWidth: maxWidth),
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							const SizedBox(height: 60),
							Container(
								width: 96,
								height: 96,
								decoration: BoxDecoration(
									color: AppColors.surface,
									border: Border.all(color: AppColors.border),
									borderRadius: BorderRadius.circular(AppRadius.xl),
									boxShadow: [
										BoxShadow(
											color: Colors.black.withValues(alpha: 0.03),
											blurRadius: 10,
											offset: const Offset(0, 6),
										),
									],
								),
								child: Icon(icon, size: 44, color: AppColors.primary),
							),
							const SizedBox(height: AppSpacing.lg),
							Text(
								title,
								style: AppTypography.headlineLarge,
								textAlign: TextAlign.center,
							),
							if (detail != null) ...[
								const SizedBox(height: AppSpacing.md),
								Text(
									detail!,
									style: AppTypography.bodyMedium.copyWith(
										color: AppColors.textSecondary,
									),
									textAlign: TextAlign.center,
								),
							],
							const SizedBox(height: AppSpacing.xs),
							Text(
								description,
								style: AppTypography.bodySmall.copyWith(
									color: AppColors.textSecondary,
								),
								textAlign: TextAlign.center,
							),
							if (button != null) ...[
								const SizedBox(height: AppSpacing.lg),
								button!,
							],
							const SizedBox(height: 60),
						],
					),
				),
			),
		);
	}
}