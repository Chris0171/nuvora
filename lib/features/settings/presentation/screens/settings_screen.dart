import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/tasks/application/controllers/task_provider.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class SettingsScreen extends ConsumerWidget {
	const SettingsScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
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

		return Scaffold(
			body: SafeArea(
				child: ListView(
					padding: const EdgeInsets.fromLTRB(
						AppSpacing.lg,
						AppSpacing.lg,
						AppSpacing.lg,
						100,
					),
					children: [
						const Text('Settings', style: AppTypography.displaySmall),
						const SizedBox(height: AppSpacing.sm),
						Text(
							'Configure your product experience',
							style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
						),
						const SizedBox(height: AppSpacing.lg),
						const _ProfileCard(),
						const SizedBox(height: AppSpacing.lg),
						_SettingsContent(
							tasksManaged: tasks.length,
							notesStored: notes.length,
							completionPercentage: completionPercentage,
						),
					],
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
	});

	final int tasksManaged;
	final int notesStored;
	final int completionPercentage;

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				_SettingsGroup(
					title: 'Account',
					items: [
						const _SettingsItemData('Profile', Icons.person_outline),
						const _SettingsItemData('Plan & billing', Icons.credit_card_outlined),
						const _SettingsItemData('Security', Icons.lock_outline),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				_SettingsGroup(
					title: 'Appearance',
					items: const [
						_SettingsItemData('Theme', Icons.dark_mode_outlined),
						_SettingsItemData('Typography', Icons.text_fields_outlined),
						_SettingsItemData('Layout density', Icons.space_dashboard_outlined),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				_SettingsGroup(
					title: 'Notifications',
					items: const [
						_SettingsItemData('Push alerts', Icons.notifications_none),
						_SettingsItemData('Reminder cadence', Icons.alarm_outlined),
						_SettingsItemData('Digest summary', Icons.summarize_outlined),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				_SettingsGroup(
					title: 'Data & Backup',
					items: const [
						_SettingsItemData('Auto backup', Icons.cloud_outlined),
						_SettingsItemData('Export workspace', Icons.download_outlined),
						_SettingsItemData('Storage usage', Icons.storage_outlined),
					],
				),
				const SizedBox(height: AppSpacing.lg),
				_SettingsGroup(
					title: 'About Nuvora',
					items: [
						const _SettingsItemData('Version', Icons.info_outline),
						const _SettingsItemData('Help center', Icons.help_outline),
						const _SettingsItemData('Privacy policy', Icons.policy_outlined),
						_SettingsItemData('Tasks managed: $tasksManaged', Icons.task_alt),
						_SettingsItemData('Notes stored: $notesStored', Icons.note_alt_outlined),
						_SettingsItemData('Completion: $completionPercentage%', Icons.bar_chart_outlined),
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
			),
			child: const Row(
				children: [
					CircleAvatar(
						radius: 24,
						backgroundColor: AppColors.primaryLight,
						child: Icon(Icons.person, color: AppColors.primary),
					),
					SizedBox(width: AppSpacing.md),
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text('Nuvora User', style: AppTypography.headlineSmall),
							SizedBox(height: AppSpacing.xs),
							Text('Productivity plan', style: AppTypography.bodySmall),
						],
					),
				],
			),
		);
	}
}

class _SettingsGroup extends StatelessWidget {
	const _SettingsGroup({required this.title, required this.items});

	final String title;
	final List<_SettingsItemData> items;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(AppSpacing.lg),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(AppRadius.xl),
				border: Border.all(color: AppColors.border),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(title, style: AppTypography.headlineSmall),
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
					Icon(item.icon, size: 18, color: AppColors.primary),
					const SizedBox(width: AppSpacing.md),
					Text(item.label, style: AppTypography.bodyMedium),
					const Spacer(),
					const Icon(Icons.chevron_right, color: AppColors.textTertiary),
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
					colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
			),
			child: const Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Nuvora Pro',
						style: TextStyle(
							color: Colors.white,
							fontSize: 18,
							fontWeight: FontWeight.w700,
						),
					),
					SizedBox(height: AppSpacing.sm),
					Text('Unlimited productivity insights', style: TextStyle(color: Colors.white70)),
					SizedBox(height: AppSpacing.xs),
					Text('Advanced analytics', style: TextStyle(color: Colors.white70)),
					SizedBox(height: AppSpacing.xs),
					Text('Smart reminders', style: TextStyle(color: Colors.white70)),
				],
			),
		);
	}
}

class _SettingsItemData {
	const _SettingsItemData(this.label, this.icon);

	final String label;
	final IconData icon;
}
