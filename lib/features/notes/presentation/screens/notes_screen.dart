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

class NotesScreen extends ConsumerStatefulWidget {
	const NotesScreen({super.key});

	@override
	ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
	bool _showArchived = false;
	late final TextEditingController _searchController;

	@override
	void initState() {
		super.initState();
		_searchController = TextEditingController(
			text: ref.read(noteSearchQueryProvider),
		);
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final horizontalPadding = AppResponsive.pagePadding(context);
		final maxWidth = AppResponsive.maxContentWidth(context);
		final titleScale = AppResponsive.titleScale(context);
		final motionDuration = AppMotion.resolvedDuration(context, AppMotion.duration);
		final motionCurve = AppMotion.resolvedCurve(context, AppMotion.curve);

		final notesAsync = _showArchived
			? ref.watch(archivedNotesProvider)
			: ref.watch(activeNotesProvider);
		final searchQuery = ref.watch(noteSearchQueryProvider);

		if (_searchController.text != searchQuery) {
			_searchController.text = searchQuery;
		}

		final noteCount = notesAsync.maybeWhen(
			data: (notes) => notes.length,
			orElse: () => null,
		);
		final notesState = notesAsync.when(
			data: (notes) => _NotesBody(
				key: ValueKey('notes-data-${notes.length}-$searchQuery-$_showArchived'),
				notes: notes,
				hasSearch: !_showArchived && searchQuery.isNotEmpty,
				isArchivedView: _showArchived,
				onClearSearch: () {
					_searchController.clear();
					ref.read(noteSearchQueryProvider.notifier).state = '';
				},
			),
			loading: () => _LoadingState(
				key: ValueKey('notes-loading-$_showArchived'),
				label: _showArchived ? 'Loading archived notes...' : 'Loading notes...',
			),
			error: (error, _) => _ErrorState(
				key: ValueKey('notes-error-$_showArchived'),
				title: _showArchived ? 'Error loading archived notes' : 'Error loading notes',
				error: error,
				onRetry: () {
					ref.invalidate(activeNotesProvider);
					ref.invalidate(archivedNotesProvider);
				},
			),
		);

		final lifecycleTabs = Padding(
			padding: EdgeInsets.symmetric(
				horizontal: horizontalPadding,
				vertical: AppSpacing.sm,
			),
			child: Row(
				children: [
					Expanded(
						child: ChoiceChip(
							key: const ValueKey('notes-filter-active'),
							label: const Text('Active Notes'),
							selected: !_showArchived,
							onSelected: (selected) {
								if (!selected) return;
								setState(() => _showArchived = false);
							},
						),
					),
					const SizedBox(width: AppSpacing.sm),
					Expanded(
						child: ChoiceChip(
							key: const ValueKey('notes-filter-archived'),
							label: const Text('Archived'),
							selected: _showArchived,
							onSelected: (selected) {
								if (!selected) return;
								setState(() => _showArchived = true);
							},
						),
					),
				],
			),
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
																	_showArchived ? 'Archived Notes' : 'Notes',
																	style: AppTypography.displaySmall.copyWith(
																		fontSize: AppTypography.displaySmall.fontSize! * titleScale,
																	),
																),
																const SizedBox(height: AppSpacing.xs),
																Text(
																	_showArchived
																		? 'Revisit and restore your archived ideas.'
																		: 'Capture, connect, and revisit your ideas.',
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
																_showArchived ? '$noteCount archived' : '$noteCount notes',
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
												controller: _searchController,
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
													suffixIcon: searchQuery.isNotEmpty
														? IconButton(
															icon: const Icon(Icons.clear, size: 20),
															tooltip: 'Clear search',
															color: AppColors.textSecondary,
															onPressed: () {
																_searchController.clear();
																ref.read(noteSearchQueryProvider.notifier).state = '';
															},
														)
														: null,
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
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								lifecycleTabs,
								AnimatedSwitcher(
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
							],
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
					ref.invalidate(activeNotesProvider);
					ref.invalidate(archivedNotesProvider);
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
	const _LoadingState({super.key, this.label = 'Loading notes...'});

	final String label;

	@override
	Widget build(BuildContext context) {
		return AppLoadingState(label: label);
	}
}

class _ErrorState extends StatelessWidget {
	const _ErrorState({
		super.key,
		this.title = 'Error loading notes',
		required this.error,
		this.onRetry,
	});

	final String title;
	final Object error;
	final VoidCallback? onRetry;

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						const SizedBox(height: 60),
						Container(
							width: 80,
							height: 80,
							decoration: BoxDecoration(
								color: AppColors.danger.withValues(alpha: 0.1),
								borderRadius: BorderRadius.circular(AppRadius.xl),
								border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
							),
							child: const Icon(
								Icons.error_outline,
								size: 40,
								color: AppColors.danger,
							),
						),
						const SizedBox(height: AppSpacing.lg),
						Text(
							title,
							style: AppTypography.headlineMedium,
							textAlign: TextAlign.center,
						),
						const SizedBox(height: AppSpacing.md),
						Text(
							error.toString(),
							style: AppTypography.bodySmall.copyWith(
								color: AppColors.textSecondary,
							),
							textAlign: TextAlign.center,
						),
						if (onRetry != null) ...[
							const SizedBox(height: AppSpacing.lg),
							ElevatedButton.icon(
								onPressed: onRetry,
								icon: const Icon(Icons.refresh),
								label: const Text('Retry'),
							),
						],
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
		this.isArchivedView = false,
		this.onClearSearch,
	});

	final List<Note> notes;
	final bool hasSearch;
	final bool isArchivedView;
	final VoidCallback? onClearSearch;

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
			if (isArchivedView) {
				return const AppEmptyState(
					key: ValueKey('notes-archived-empty'),
					icon: Icons.archive_outlined,
					title: 'No archived notes',
					detail: 'No archived notes yet',
					description: 'Archived notes remain available for reference',
				);
			}

			if (hasSearch) {
				return AppEmptyState(
					key: ValueKey('notes-empty-$hasSearch'),
					icon: Icons.search_off_outlined,
					title: 'No notes found',
					description: 'Try adjusting your search',
					button: onClearSearch != null
						? ElevatedButton.icon(
							onPressed: onClearSearch,
							icon: const Icon(Icons.clear),
							label: const Text('Clear search'),
						)
						: null,
				);
			}

			return AppEmptyState(
				key: ValueKey('notes-empty-$hasSearch'),
				icon: Icons.note_outlined,
				title: 'Capture your first idea',
				detail: 'No notes yet',
				description: 'Create your first note',
				button: ElevatedButton.icon(
					onPressed: () async {
						await Navigator.of(context).push(
							AppPageRoute<void>(builder: (_) => const CreateNoteScreen()),
						);
						ref.invalidate(notesProvider);
						ref.invalidate(activeNotesProvider);
						ref.invalidate(archivedNotesProvider);
					},
					icon: const Icon(Icons.lightbulb_outline),
					label: const Text('Create your first note'),
				),
			);
		}

		final pinnedNotes = notes.where((note) => note.isPinned).toList();
		final recentNotes = [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
		final recentUnpinnedNotes = recentNotes.where((note) => !note.isPinned).toList();
		final suggestedReviewCount = recentNotes.take(3).length;
		final recentCount = ProductivityAnalyzer.getRecentNotesCount(notes);

		if (isArchivedView) {
			return Padding(
				key: const ValueKey('notes-archived-content'),
				padding: EdgeInsets.symmetric(
					horizontal: horizontalPadding,
					vertical: AppSpacing.md,
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						if (pinnedNotes.isNotEmpty) ...[
							_SectionHeader(
								title: 'Pinned archived notes',
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
										onTap: () => _openEditNote(context, ref, note),
										onDelete: () => _deleteNote(context, ref, note.id),
										onTogglePin: () => _togglePin(context, ref, note),
										onToggleArchive: () => _toggleArchive(context, ref, note),
									);
								},
							),
							const SizedBox(height: AppSpacing.xl),
							_SectionHeader(
								title: 'Other archived notes',
								icon: Icons.archive_outlined,
								count: recentUnpinnedNotes.length,
							),
						] else ...[
							_SectionHeader(
								title: 'Archived notes',
								icon: Icons.archive_outlined,
								count: notes.length,
							),
						],
						const SizedBox(height: AppSpacing.md),
						ListView.builder(
							shrinkWrap: true,
							physics: const NeverScrollableScrollPhysics(),
							itemCount: isArchivedView && pinnedNotes.isNotEmpty
								? recentUnpinnedNotes.length
								: notes.length,
							itemBuilder: (context, index) {
								final note = isArchivedView && pinnedNotes.isNotEmpty
									? recentUnpinnedNotes[index]
									: notes[index];
								return Padding(
									padding: const EdgeInsets.only(bottom: AppSpacing.md),
									child: NoteItem(
										key: ValueKey(note.id),
										note: note,
										onTap: () => _openEditNote(context, ref, note),
										onDelete: () => _deleteNote(context, ref, note.id),
										onTogglePin: () => _togglePin(context, ref, note),
										onToggleArchive: () => _toggleArchive(context, ref, note),
									),
								);
							},
						),
					],
				),
			);
		}

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
									onTap: () => _openEditNote(context, ref, note),
									onDelete: () => _deleteNote(context, ref, note.id),
									onTogglePin: () => _togglePin(context, ref, note),
									onToggleArchive: () => _toggleArchive(context, ref, note),
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
									onTap: () => _openEditNote(context, ref, note),
									onDelete: () => _deleteNote(context, ref, note.id),
									onTogglePin: () => _togglePin(context, ref, note),
									onToggleArchive: () => _toggleArchive(context, ref, note),
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
			ref.invalidate(activeNotesProvider);
			ref.invalidate(archivedNotesProvider);
		} catch (_) {
			if (context.mounted) {
				AppFeedback.showSnackBar(context, 'Could not delete note');
			}
		}
	}

	Future<void> _togglePin(BuildContext context, WidgetRef ref, Note note) async {
		try {
			HapticFeedback.selectionClick();
			await ref.read(noteControllerProvider).togglePin(note);
			ref.invalidate(notesProvider);
			ref.invalidate(activeNotesProvider);
			ref.invalidate(archivedNotesProvider);
		} catch (_) {
			if (context.mounted) {
				AppFeedback.showSnackBar(
					context,
					note.isPinned ? 'Could not unpin note' : 'Could not pin note',
				);
			}
		}
	}

	Future<void> _toggleArchive(BuildContext context, WidgetRef ref, Note note) async {
		final willArchive = !note.archived;
		try {
			HapticFeedback.selectionClick();
			if (willArchive) {
				await ref.read(noteControllerProvider).archiveNote(note);
			} else {
				await ref.read(noteControllerProvider).unarchiveNote(note);
			}
			ref.invalidate(notesProvider);
			ref.invalidate(activeNotesProvider);
			ref.invalidate(archivedNotesProvider);
			if (context.mounted) {
				AppFeedback.showSnackBar(
					context,
					willArchive ? 'Note archived' : 'Note unarchived',
				);
			}
		} catch (_) {
			if (context.mounted) {
				AppFeedback.showSnackBar(
					context,
					willArchive ? 'Could not archive note' : 'Could not unarchive note',
				);
			}
		}
	}

	Future<void> _openEditNote(BuildContext context, WidgetRef ref, Note note) async {
		await Navigator.of(context).push(
			AppPageRoute<void>(
				builder: (_) => CreateNoteScreen(initialNote: note),
			),
		);
		ref.invalidate(notesProvider);
		ref.invalidate(activeNotesProvider);
		ref.invalidate(archivedNotesProvider);
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
		required this.onTap,
		required this.onDelete,
		required this.onTogglePin,
		this.onToggleArchive,
	});

	final Note note;
	final VoidCallback onTap;
	final VoidCallback onDelete;
	final VoidCallback onTogglePin;
	final VoidCallback? onToggleArchive;

	String _formatDate(DateTime date) {
		final now = DateTime.now();
		final difference = now.difference(date);

		if (difference.isNegative || difference.inDays == 0) {
			return 'Today';
		} else if (difference.inDays == 1) {
			return 'Yesterday';
		} else if (difference.inDays < 7) {
			return '${difference.inDays} days ago';
		} else if (difference.inDays < 30) {
			final weeks = (difference.inDays / 7).floor();
			return '$weeks week${weeks > 1 ? 's' : ''} ago';
		} else {
			return '${date.month}/${date.day}/${date.year}';
		}
	}

	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(AppRadius.lg),
				child: Container(
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
									AppIconActionButton(
										icon: Icons.push_pin,
										label: 'Unpin note ${note.title}',
										color: AppColors.warning,
										onPressed: onTogglePin,
									),
									AppIconActionButton(
										icon: note.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
										label: note.archived
											? 'Unarchive note ${note.title}'
											: 'Archive note ${note.title}',
										onPressed: onToggleArchive,
									),
									const Spacer(),
									AppIconActionButton(
										icon: Icons.close,
										label: 'Delete pinned note ${note.title}',
										onPressed: onDelete,
									),
								],
							),
							const SizedBox(height: AppSpacing.xs),
							Text(
								note.title,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: AppTypography.labelLarge,
							),
							const SizedBox(height: AppSpacing.xs),
							Expanded(
								child: Text(
									note.content,
									maxLines: 4,
									overflow: TextOverflow.ellipsis,
									style: AppTypography.bodySmall.copyWith(
										color: AppColors.textSecondary,
									),
								),
							),
							const SizedBox(height: AppSpacing.xs),
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
									_formatDate(note.updatedAt),
									style: AppTypography.labelSmall.copyWith(
										color: AppColors.textSecondary,
									),
								),
							),
						],
					),
				),
			),
		);
	}
}
