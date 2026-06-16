import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/presentation/screens/create_note_screen.dart';
import 'package:nuvora/features/notes/presentation/widgets/note_item.dart';

class NotesScreen extends ConsumerWidget {
	const NotesScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final notesAsync = ref.watch(notesProvider);
		final searchQuery = ref.watch(noteSearchQueryProvider);

		return Scaffold(
			body: CustomScrollView(
				slivers: [
					SliverAppBar(
						floating: true,
						elevation: 0,
						backgroundColor: Colors.transparent,
						title: const Text('Notes'),
						bottom: PreferredSize(
							preferredSize: const Size.fromHeight(70),
							child: Padding(
								padding: const EdgeInsets.fromLTRB(
									AppSpacing.lg,
									0,
									AppSpacing.lg,
									AppSpacing.lg,
								),
								child: TextField(
									onChanged: (value) =>
										ref.read(noteSearchQueryProvider.notifier).state = value,
									decoration: InputDecoration(
										hintText: 'Search notes...',
										prefixIcon: const Icon(Icons.search),
										border: OutlineInputBorder(
											borderRadius: BorderRadius.circular(AppRadius.lg),
										),
									),
								),
							),
						),
					),
					SliverToBoxAdapter(
						child: notesAsync.when(
							data: (notes) => _NotesBody(
								notes: notes,
								hasSearch: searchQuery.isNotEmpty,
							),
							loading: () => const _LoadingState(),
							error: (error, _) => _ErrorState(error: error),
						),
					),
				],
			),
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () async {
					await Navigator.of(context).push(
						MaterialPageRoute<void>(
							builder: (_) => const CreateNoteScreen(),
						),
					);
					ref.invalidate(notesProvider);
				},
				icon: const Icon(Icons.add),
				label: const Text('New Note'),
			),
		);
	}
}

class _LoadingState extends StatelessWidget {
	const _LoadingState();

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(AppSpacing.lg),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						const SizedBox(height: 60),
						const CircularProgressIndicator(
							color: AppColors.primary,
						),
						const SizedBox(height: AppSpacing.lg),
						Text(
							'Loading notes...',
							style: AppTypography.bodyMedium.copyWith(
								color: AppColors.textSecondary,
							),
						),
						const SizedBox(height: 60),
					],
				),
			),
		);
	}
}

class _ErrorState extends StatelessWidget {
	const _ErrorState({required this.error});

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
		required this.notes,
		required this.hasSearch,
	});

	final List<Note> notes;
	final bool hasSearch;

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		if (notes.isEmpty) {
			return Padding(
				padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						const SizedBox(height: 60),
						Container(
							width: 80,
							height: 80,
							decoration: BoxDecoration(
								color: AppColors.primaryLight,
								borderRadius: BorderRadius.circular(AppRadius.xl),
							),
							child: const Icon(
								Icons.note_outlined,
								size: 40,
								color: AppColors.primary,
							),
						),
						const SizedBox(height: AppSpacing.lg),
						Text(
							hasSearch ? 'No notes found' : 'No notes yet',
							style: AppTypography.headlineMedium,
							textAlign: TextAlign.center,
						),
						const SizedBox(height: AppSpacing.md),
						Text(
							hasSearch ? 'Try adjusting your search' : 'Create your first note',
							style: AppTypography.bodyMedium.copyWith(
								color: AppColors.textSecondary,
							),
							textAlign: TextAlign.center,
						),
						const SizedBox(height: 60),
					],
				),
			);
		}

		return Padding(
			padding: const EdgeInsets.symmetric(
				horizontal: AppSpacing.lg,
				vertical: AppSpacing.md,
			),
			child: ListView.builder(
				shrinkWrap: true,
				physics: const NeverScrollableScrollPhysics(),
				itemCount: notes.length,
				itemBuilder: (context, index) {
					final note = notes[index];
					return Padding(
						padding: const EdgeInsets.only(bottom: AppSpacing.md),
						child: NoteItem(
							key: ValueKey(note.id),
							note: note,
							onDelete: () async {
								try {
									await ref.read(noteControllerProvider).deleteNote(note.id);
									ref.invalidate(notesProvider);
								} catch (_) {
									if (context.mounted) {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(
												content: Text('Could not delete note'),
											),
										);
									}
								}
							},
						),
					);
				},
			),
		);
	}
}
