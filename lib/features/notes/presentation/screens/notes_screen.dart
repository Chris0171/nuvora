import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/app_page_route.dart';
import 'package:nuvora/core/productivity/productivity_analyzer.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_feedback.dart';
import 'package:nuvora/core/widgets/app_icon_action_button.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
import 'package:nuvora/core/widgets/app_responsive.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/presentation/screens/create_note_screen.dart';
import 'package:nuvora/features/notes/presentation/widgets/note_item.dart';

class NotesScreen extends ConsumerWidget {
	const NotesScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final maxWidth = AppResponsive.maxContentWidth(context);
		final titleScale = AppResponsive.titleScale(context);
		final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
		final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);

		final notesAsync = ref.watch(notesProvider);
		final searchQuery = ref.watch(noteSearchQueryProvider);
		final noteCount = notesAsync.maybeWhen(
			data: (notes) => notes.length,
			orElse: () => null,
		);
		final notesState = notesAsync.when(
			data: (notes) => _NotesBody(
				key: ValueKey('notes-data-${notes.length}-$searchQuery'),
				notes: notes,
				hasSearch: searchQuery.isNotEmpty,
			),
			loading: () => const _LoadingState(key: ValueKey('notes-loading')),
			error: (error, _) => _ErrorState(key: const ValueKey('notes-error'), error: error),
		);

		return Scaffold(
			body: FadeSlideIn(
				child: Align(
					alignment: Alignment.topCenter,
					child: ConstrainedBox(
						constraints: BoxConstraints(maxWidth: maxWidth),
						child: CustomScrollView(
							slivers: [
					SliverAppBar(
						floating: true,
						elevation: 0,
						backgroundColor: Colors.transparent,
						title: const SizedBox.shrink(),
						bottom: PreferredSize(
							preferredSize: const Size.fromHeight(168),
							child: Padding(
								padding: EdgeInsets.fromLTRB(
									horizontalPadding,
									0,
									horizontalPadding,
									AppSpacing.lg,
								),
								child: Column(
									children: [
										Container(
											width: double.infinity,
											padding: const EdgeInsets.all(AppSpacing.lg),
											decoration: BoxDecoration(
												color: AppColors.surface,
												borderRadius: BorderRadius.circular(AppRadius.xl),
												border: Border.all(color: AppColors.border),
												boxShadow: [
													BoxShadow(
														color: Colors.black.withValues(alpha: 0.03),
														blurRadius: 8,
														offset: const Offset(0, 4),
													),
												],
											),
											child: Row(
												children: [
													Expanded(
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Text(
																	'Notes',
																	style: AppTypography.displaySmall.copyWith(
																		fontSize: AppTypography.displaySmall.fontSize! * titleScale,
																	),
																),
																const SizedBox(height: AppSpacing.xs),
																Text(
																	'Capture, connect, and revisit your ideas.',
																	style: AppTypography.bodySmall.copyWith(
																		color: AppColors.textSecondary,
																	),
																),
															],
														),
													),
													if (noteCount != null)
														AnimatedContainer(
															duration: AppMotion.duration,
															padding: const EdgeInsets.symmetric(
																horizontal: AppSpacing.md,
																vertical: AppSpacing.sm,
															),
															decoration: BoxDecoration(
																color: AppColors.surfaceSecondary,
																borderRadius: BorderRadius.circular(AppRadius.full),
															),
															child: Text(
																'$noteCount notes',
																style: AppTypography.labelSmall.copyWith(
																	color: AppColors.textSecondary,
																),
															),
														),
												],
											),
										),
										const SizedBox(height: AppSpacing.md),
										Container(
											decoration: BoxDecoration(
												color: AppColors.surface,
												borderRadius: BorderRadius.circular(AppRadius.xl),
												border: Border.all(color: AppColors.border),
											),
											child: TextField(
												onChanged: (value) =>
													ref.read(noteSearchQueryProvider.notifier).state = value,
												decoration: InputDecoration(
													hintText: 'Search notes...',
													prefixIcon: Padding(
														padding: const EdgeInsets.only(left: AppSpacing.sm),
														child: Icon(
															Icons.search,
															color: AppColors.textSecondary.withValues(alpha: 0.9),
														),
													),
													prefixIconConstraints: const BoxConstraints(
														minWidth: 44,
														minHeight: 44,
													),
													filled: true,
													fillColor: AppColors.surfaceSecondary,
													contentPadding: const EdgeInsets.symmetric(
														horizontal: AppSpacing.md,
														vertical: AppSpacing.md,
													),
													border: OutlineInputBorder(
														borderRadius: BorderRadius.circular(AppRadius.xl),
														borderSide: BorderSide.none,
													),
													enabledBorder: OutlineInputBorder(
														borderRadius: BorderRadius.circular(AppRadius.xl),
														borderSide: BorderSide.none,
													),
													focusedBorder: OutlineInputBorder(
														borderRadius: BorderRadius.circular(AppRadius.xl),
														borderSide: const BorderSide(color: AppColors.border),
													),
												),
											),
										),
									],
								),
							),
						),
					),
					SliverToBoxAdapter(
						child: AnimatedSwitcher(
							duration: motionDuration,
							switchInCurve: motionCurve,
							switchOutCurve: motionCurve,
							transitionBuilder: (child, animation) {
								return FadeTransition(
									opacity: animation,
									child: SlideTransition(
										position: Tween<Offset>(
											begin: AppMotion.subtleOffset,
											end: Offset.zero,
										).animate(animation),
										child: child,
									),
								);
							},
							child: notesState,
						),
					),
				],
						),
					),
				),
			),
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () async {
					await Navigator.of(context).push(
						AppPageRoute<void>(
							builder: (_) => const CreateNoteScreen(),
						),
					);
					ref.invalidate(notesProvider);
				},
				backgroundColor: AppColors.surface,
				foregroundColor: AppColors.textPrimary,
				elevation: AppElevation.md,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(AppRadius.xl),
					side: const BorderSide(color: AppColors.border),
				),
				icon: const Icon(Icons.add, color: AppColors.primary),
				label: const Text('New Note'),
			),
		);
	}
}

class _LoadingState extends StatelessWidget {
	const _LoadingState({super.key});

	@override
	Widget build(BuildContext context) {
		return const AppLoadingState(label: 'Loading notes...');
	}
}

class _ErrorState extends StatelessWidget {
	const _ErrorState({super.key, required this.error});

	final Object error;

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						const SizedBox(height: 60),
						const Icon(
							Icons.error_outline,
							size: 48,
							color: AppColors.danger,
						),
						const SizedBox(height: AppSpacing.lg),
						Text(
							'Error loading notes',
							style: AppTypography.headlineMedium,
							textAlign: TextAlign.center,
						),
						const SizedBox(height: AppSpacing.md),
						Text(
							error.toString(),
							style: AppTypography.bodySmall,
							textAlign: TextAlign.center,
						),
						const SizedBox(height: 60),
					],
				),
			),
		);
	}
}

class _NotesBody extends ConsumerWidget {
	const _NotesBody({
		super.key,
		required this.notes,
		required this.hasSearch,
	});

	final List<Note> notes;
	final bool hasSearch;

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final pinnedColumns = AppResponsive.adaptiveColumns(
			context,
			mobile: 1,
			tablet: 2,
			desktop: 3,
		);

		if (notes.isEmpty) {
			return AppEmptyState(
				key: ValueKey('notes-empty-$hasSearch'),
				icon: Icons.note_outlined,
				title: hasSearch ? 'No notes found' : 'Capture your first idea',
				detail: hasSearch ? null : 'No notes yet',
				description: hasSearch ? 'Try adjusting your search' : 'Create your first note',
				button: !hasSearch
					? ElevatedButton.icon(
						onPressed: () async {
							await Navigator.of(context).push(
								AppPageRoute<void>(builder: (_) => const CreateNoteScreen()),
							);
							ref.invalidate(notesProvider);
						},
						icon: const Icon(Icons.lightbulb_outline),
						label: const Text('Create your first note'),
					)
					: null,
			);
		}

		final pinnedNotes = notes.where((note) => note.isPinned).toList();
		final recentNotes = [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
		final recentUnpinnedNotes = recentNotes.where((note) => !note.isPinned).toList();
		final suggestedReviewCount = recentNotes.take(3).length;
		final recentCount = ProductivityAnalyzer.getRecentNotesCount(notes);

		return Padding(
			key: const ValueKey('notes-content'),
			padding: EdgeInsets.symmetric(
				horizontal: horizontalPadding,
				vertical: AppSpacing.md,
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						width: double.infinity,
						padding: const EdgeInsets.all(AppSpacing.lg),
						decoration: BoxDecoration(
							color: AppColors.surface,
							borderRadius: BorderRadius.circular(AppRadius.xl),
							border: Border.all(color: AppColors.border),
							boxShadow: [
								BoxShadow(
									color: Colors.black.withValues(alpha: 0.03),
									blurRadius: 8,
									offset: const Offset(0, 4),
								),
							],
						),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text('Knowledge summary', style: AppTypography.headlineMedium),
								const SizedBox(height: AppSpacing.md),
								_SummaryRow(label: 'You have notes', value: '${notes.length}'),
								const SizedBox(height: AppSpacing.sm),
								_SummaryRow(label: 'Pinned ideas', value: '${pinnedNotes.length}'),
								const SizedBox(height: AppSpacing.sm),
								_SummaryRow(label: 'Created recently', value: '$recentCount'),
							],
						),
					),
					const SizedBox(height: AppSpacing.xl),
					if (pinnedNotes.isNotEmpty) ...[
						_SectionHeader(
							title: 'Pinned notes',
							icon: Icons.push_pin_outlined,
							count: pinnedNotes.length,
						),
						const SizedBox(height: AppSpacing.md),
						GridView.builder(
							shrinkWrap: true,
							physics: const NeverScrollableScrollPhysics(),
							gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
								crossAxisCount: pinnedColumns,
								crossAxisSpacing: AppSpacing.md,
								mainAxisSpacing: AppSpacing.md,
								childAspectRatio: 1.05,
							),
							itemCount: pinnedNotes.length,
							itemBuilder: (context, index) {
								final note = pinnedNotes[index];
								return _PinnedNoteCard(
									note: note,
									onDelete: () => _deleteNote(context, ref, note.id),
								);
							},
						),
						const SizedBox(height: AppSpacing.xl),
					],
					_SectionHeader(
						title: 'Recent notes',
						icon: Icons.history,
						count: recentUnpinnedNotes.length,
					),
					const SizedBox(height: AppSpacing.md),
					ListView.builder(
						shrinkWrap: true,
						physics: const NeverScrollableScrollPhysics(),
						itemCount: recentUnpinnedNotes.length,
						itemBuilder: (context, index) {
							final note = recentUnpinnedNotes[index];
							return Padding(
								padding: const EdgeInsets.only(bottom: AppSpacing.md),
								child: NoteItem(
									key: ValueKey(note.id),
									note: note,
									onDelete: () => _deleteNote(context, ref, note.id),
								),
							);
						},
					),
					const SizedBox(height: AppSpacing.lg),
					const _SectionHeader(
						title: 'Suggested review',
						icon: Icons.lightbulb_outline,
					),
					const SizedBox(height: AppSpacing.md),
					Container(
						width: double.infinity,
						padding: const EdgeInsets.all(AppSpacing.md),
						decoration: BoxDecoration(
							color: AppColors.surfaceSecondary,
							borderRadius: BorderRadius.circular(AppRadius.lg),
							border: Border.all(color: AppColors.border),
						),
						child: Text(
							'Review $suggestedReviewCount recent notes to keep ideas fresh.',
							style: AppTypography.bodySmall.copyWith(
								color: AppColors.textSecondary,
							),
						),
					),
				],
			),
		);
	}

	Future<void> _deleteNote(BuildContext context, WidgetRef ref, String id) async {
		try {
			HapticFeedback.mediumImpact();
			await ref.read(noteControllerProvider).deleteNote(id);
			ref.invalidate(notesProvider);
		} catch (_) {
			if (context.mounted) {
				AppFeedback.showSnackBar(context, 'Could not delete note');
			}
		}
	}
}

class _SummaryRow extends StatelessWidget {
	const _SummaryRow({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Text(
					label,
					style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
				),
				const Spacer(),
				Text(value, style: AppTypography.labelLarge),
			],
		);
	}
}


class _SectionHeader extends StatelessWidget {
	const _SectionHeader({required this.title, required this.icon, this.count});

	final String title;
	final IconData icon;
	final int? count;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: [
				Icon(icon, size: 18, color: AppColors.primary),
				const SizedBox(width: AppSpacing.sm),
				Text(title, style: AppTypography.headlineSmall),
				if (count != null) ...[
					const SizedBox(width: AppSpacing.sm),
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
							'$count',
							style: AppTypography.labelSmall.copyWith(
								color: AppColors.textSecondary,
							),
						),
					),
				],
			],
		);
	}
}

class _PinnedNoteCard extends StatelessWidget {
	const _PinnedNoteCard({
		required this.note,
		required this.onDelete,
	});

	final Note note;
	final VoidCallback onDelete;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(AppSpacing.md),
			decoration: BoxDecoration(
				color: AppColors.surface,
				borderRadius: BorderRadius.circular(AppRadius.lg),
				border: Border.all(color: AppColors.border),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.03),
						blurRadius: 8,
						offset: const Offset(0, 4),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							const Icon(Icons.push_pin, size: 16, color: AppColors.warning),
							const Spacer(),
							AppIconActionButton(
								icon: Icons.close,
								label: 'Delete pinned note ${note.title}',
								onPressed: onDelete,
							),
						],
					),
					Text(
						note.title,
						maxLines: 2,
						overflow: TextOverflow.ellipsis,
						style: AppTypography.labelLarge,
					),
					const SizedBox(height: AppSpacing.sm),
					Expanded(
						child: Text(
							note.content,
							maxLines: 4,
							overflow: TextOverflow.ellipsis,
							style: AppTypography.bodySmall,
						),
					),
				],
			),
		);
	}
}
