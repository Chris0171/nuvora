import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class SettingsScreen extends ConsumerWidget {
	const SettingsScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final maxWidth = AppResponsive.maxContentWidth(context);
		final titleScale = AppResponsive.titleScale(context);

		final tasks = ref.watch(tasksProvider).maybeWhen(
			data: (items) => items,
			orElse: () => <Task>[],
		);
		final notes = ref.watch(notesProvider).maybeWhen(
			data: (items) => items,
			orElse: () => <Note>[],
		);
		final completionRate = ProductivityAnalyzer.calculateCompletionRate(tasks);
		final completionPercentage = (completionRate * 100).round();
		final pendingTasks = tasks.where((task) => !task.isCompleted).length;

		return Scaffold(
			body: SafeArea(
				child: FadeSlideIn(
					child: Align(
						alignment: Alignment.topCenter,
						child: ConstrainedBox(
							constraints: BoxConstraints(maxWidth: maxWidth),
							child: ListView(
								padding: EdgeInsets.fromLTRB(
									horizontalPadding,
									AppSpacing.lg,
									horizontalPadding,
									100,
								),
								children: [
						Text(
							'Settings',
							style: AppTypography.displayLarge.copyWith(
								fontSize: AppTypography.displayLarge.fontSize! * titleScale,
							),
						),
						const SizedBox(height: AppSpacing.sm),
						Text(
							'Calm, polished controls for how Nuvora feels every day.',
							style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
						),
						const SizedBox(height: AppSpacing.md),
						Container(
							padding: const EdgeInsets.symmetric(
								horizontal: AppSpacing.md,
								vertical: AppSpacing.sm,
							),
							decoration: BoxDecoration(
								color: AppColors.surface,
								borderRadius: BorderRadius.circular(AppRadius.full),
								border: Border.all(color: AppColors.border),
							),
							child: Text(
								'Workspace profile',
								style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
							),
						),
						const SizedBox(height: AppSpacing.lg),
						const _ProfileCard(),
						const SizedBox(height: AppSpacing.lg),
						_SettingsContent(
							tasksManaged: tasks.length,
							notesStored: notes.length,
							completionPercentage: completionPercentage,
							pendingTasks: pendingTasks,
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

class _SettingsContent extends StatelessWidget {
	const _SettingsContent({
		required this.tasksManaged,
		required this.notesStored,
		required this.completionPercentage,
		required this.pendingTasks,
	});

	final int tasksManaged;
	final int notesStored;
	final int completionPercentage;
	final int pendingTasks;

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				_SettingsGroup(
					title: 'Appearance',
					subtitle: 'A visual layer for theme, color and reading comfort.',
					items: [
						const _SettingsItemData(
							'Theme',
							Icons.dark_mode_outlined,
							trailingText: 'System',
							enabled: false,
						),
						const _SettingsItemData(
							'Accent Color',
							Icons.palette_outlined,
							trailingText: 'Soon',
							enabled: false,
						),
						const _SettingsItemData(
							'Type Size',
							Icons.text_fields_outlined,
							trailingText: 'Default',
							enabled: false,
						),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				const _ToggleGroup(
					title: 'Notifications',
					subtitle: 'Visual placeholders for reminders and daily summaries.',
					items: [
						_ToggleItemData('Daily reminders', true),
						_ToggleItemData('Evening summary', false),
						_ToggleItemData('Priority nudges', true),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				_SettingsGroup(
					title: 'Data & Backup',
					subtitle: 'Storage and export surfaces presented as non-functional UI.',
					items: const [
						_SettingsItemData(
							'Local storage',
							Icons.storage_outlined,
							trailingText: 'On device',
							enabled: false,
						),
						_SettingsItemData(
							'Export',
							Icons.download_outlined,
							trailingText: 'Unavailable',
							enabled: false,
						),
						_SettingsItemData(
							'Backup',
							Icons.cloud_outlined,
							trailingText: 'Placeholder',
							enabled: false,
						),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				_SettingsGroup(
					title: 'About',
					subtitle: 'Product details and placeholders for public information.',
					items: [
						const _SettingsItemData(
							'Version',
							Icons.info_outline,
							trailingText: '1.0.0',
							enabled: false,
						),
						const _SettingsItemData(
							'License',
							Icons.gavel_outlined,
							trailingText: 'Placeholder',
							enabled: false,
						),
						const _SettingsItemData(
							'Developer',
							Icons.code_outlined,
							trailingText: 'Nuvora Studio',
							enabled: false,
						),
						_SettingsItemData(
							'Completed',
							Icons.task_alt,
							trailingText: '${tasksManaged - pendingTasks}',
							enabled: false,
						),
						_SettingsItemData(
							'Pending',
							Icons.pending_actions_outlined,
							trailingText: '$pendingTasks',
							enabled: false,
						),
						_SettingsItemData(
							'Notes',
							Icons.note_alt_outlined,
							trailingText: '$notesStored',
							enabled: false,
						),
						_SettingsItemData(
							'Focus',
							Icons.bar_chart_outlined,
							trailingText: '$completionPercentage%',
							enabled: false,
						),
					],
				),
				const SizedBox(height: AppSpacing.xl),
				const _NuvoraProCard(),
			],
		);
 	}
}

class _ProfileCard extends StatelessWidget {
	const _ProfileCard();

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(AppSpacing.lg),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(AppRadius.xl),
				border: Border.all(color: AppColors.border),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.03),
						blurRadius: 10,
						offset: const Offset(0, 4),
					),
				],
			),
			child: const Row(
				children: [
					CircleAvatar(
						radius: 28,
						backgroundColor: AppColors.surfaceSecondary,
						child: Icon(Icons.person, color: AppColors.primary),
					),
					SizedBox(width: AppSpacing.md),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Nuvora User', style: AppTypography.headlineMedium),
								SizedBox(height: AppSpacing.xs),
								Text(
									'Focused on clarity, planning, and steady progress.',
									style: AppTypography.bodySmall,
								),
							],
						),
					),
				],
			),
		);
	}
}

class _SettingsGroup extends StatelessWidget {
	const _SettingsGroup({
		required this.title,
		required this.items,
		this.subtitle,
	});

	final String title;
	final List<_SettingsItemData> items;
	final String? subtitle;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(AppSpacing.lg),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(AppRadius.xl),
				border: Border.all(color: AppColors.border),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.03),
						blurRadius: 10,
						offset: const Offset(0, 4),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(title, style: AppTypography.headlineSmall),
					if (subtitle != null) ...[
						const SizedBox(height: AppSpacing.xs),
						Text(
							subtitle!,
							style: AppTypography.bodySmall.copyWith(
								color: AppColors.textSecondary,
							),
						),
					],
					const SizedBox(height: AppSpacing.md),
					...items.map((item) => _SettingsRow(item: item)),
				],
			),
		);
	}
}

class _SettingsRow extends StatelessWidget {
	const _SettingsRow({required this.item});

	final _SettingsItemData item;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
			child: Row(
				children: [
					Container(
						width: 34,
						height: 34,
						decoration: BoxDecoration(
							color: item.enabled
								? AppColors.primaryLight.withValues(alpha: 0.35)
								: AppColors.surfaceSecondary,
							borderRadius: BorderRadius.circular(AppRadius.md),
						),
						child: Icon(
							item.icon,
							size: 18,
							color: item.enabled ? AppColors.primary : AppColors.textSecondary,
						),
					),
					const SizedBox(width: AppSpacing.md),
					Expanded(
						child: Text(
							item.label,
							style: AppTypography.bodyMedium.copyWith(
								color: item.enabled ? AppColors.textPrimary : AppColors.textSecondary,
							),
						),
					),
					if (item.trailingText != null) ...[
						Container(
							padding: const EdgeInsets.symmetric(
								horizontal: AppSpacing.sm,
								vertical: AppSpacing.xs,
							),
							decoration: BoxDecoration(
								color: AppColors.surfaceSecondary,
								borderRadius: BorderRadius.circular(AppRadius.full),
							),
							child: Text(
								item.trailingText!,
								style: AppTypography.labelSmall.copyWith(
									color: AppColors.textSecondary,
								),
							),
						),
						const SizedBox(width: AppSpacing.sm),
					],
					const Spacer(),
					Icon(
						Icons.chevron_right,
						color: item.enabled ? AppColors.textTertiary : AppColors.disabled,
					),
				],
			),
		);
	}
}

class _NuvoraProCard extends StatelessWidget {
	const _NuvoraProCard();

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(AppSpacing.lg),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(AppRadius.xl),
				gradient: const LinearGradient(
					colors: [Color(0xFF111827), Color(0xFF374151)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.08),
						blurRadius: 18,
						offset: const Offset(0, 8),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Nuvora Pro',
						style: AppTypography.headlineLarge.copyWith(color: Colors.white),
					),
					const SizedBox(height: AppSpacing.sm),
					Text(
						'Premium planning tools designed for deeper clarity and momentum.',
						style: AppTypography.bodySmall.copyWith(
							color: Colors.white.withValues(alpha: 0.7),
						),
					),
					const SizedBox(height: AppSpacing.md),
					Text('Advanced Insights', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.7))),
					const SizedBox(height: AppSpacing.xs),
					Text('Unlimited Statistics', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.7))),
					const SizedBox(height: AppSpacing.xs),
					Text('Smart Planning', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.7))),
					const SizedBox(height: AppSpacing.xs),
					Text('Cloud Sync', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.7))),
					const SizedBox(height: AppSpacing.xs),
					Text('AI Assistant', style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.7))),
				],
			),
		);
	}
}

class _SettingsItemData {
	const _SettingsItemData(
		this.label,
		this.icon, {
		this.trailingText,
		this.enabled = true,
	});

	final String label;
	final IconData icon;
	final String? trailingText;
	final bool enabled;
}

class _ToggleGroup extends StatelessWidget {
	const _ToggleGroup({
		required this.title,
		required this.subtitle,
		required this.items,
	});

	final String title;
	final String subtitle;
	final List<_ToggleItemData> items;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(AppSpacing.lg),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(AppRadius.xl),
				border: Border.all(color: AppColors.border),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.03),
						blurRadius: 10,
						offset: const Offset(0, 4),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(title, style: AppTypography.headlineSmall),
					const SizedBox(height: AppSpacing.xs),
					Text(
						subtitle,
						style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
					),
					const SizedBox(height: AppSpacing.md),
					...items.map((item) => _ToggleRow(item: item)),
				],
			),
		);
	}
}

class _ToggleRow extends StatelessWidget {
	const _ToggleRow({required this.item});

	final _ToggleItemData item;

	@override
	Widget build(BuildContext context) {
		return MergeSemantics(
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
				child: Semantics(
					enabled: false,
					label: item.label,
					child: Row(
						children: [
							Expanded(
								child: Text(item.label, style: AppTypography.bodyMedium),
							),
							Switch(
								value: item.value,
								onChanged: null,
								activeThumbColor: AppColors.primary,
								activeTrackColor: AppColors.primaryLight,
							),
						],
					),
				),
			),
		);
	}
}

class _ToggleItemData {
	const _ToggleItemData(this.label, this.value);

	final String label;
	final bool value;
}
