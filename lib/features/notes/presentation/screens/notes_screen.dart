import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/notes/presentation/screens/create_note_screen.dart';
import 'package:nuvora/features/notes/presentation/widgets/note_item.dart';

class NotesScreen extends ConsumerWidget {
	const NotesScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final notesAsync = ref.watch(notesProvider);

		return Scaffold(
			appBar: AppBar(title: const Text('Notes')),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(12),
						child: TextField(
							onChanged: (value) =>
									ref.read(noteSearchQueryProvider.notifier).state = value,
							decoration: const InputDecoration(
								prefixIcon: Icon(Icons.search),
								labelText: 'Buscar por titulo o contenido',
							),
						),
					),
					Expanded(
						child: notesAsync.when(
							data: (notes) => _NotesBody(notes: notes),
							loading: () =>
									const Center(child: CircularProgressIndicator()),
							error: (error, _) => Center(child: Text('Error: $error')),
						),
					),
				],
			),
			floatingActionButton: FloatingActionButton(
				onPressed: () async {
					await Navigator.of(context).push(
						MaterialPageRoute<void>(
							builder: (_) => const CreateNoteScreen(),
						),
					);
					ref.invalidate(notesProvider);
				},
				child: const Icon(Icons.add),
			),
		);
	}
}

class _NotesBody extends ConsumerWidget {
	const _NotesBody({required this.notes});

	final List<Note> notes;

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		if (notes.isEmpty) {
			return const Center(child: Text('No hay notas todavia.'));
		}

		return ListView.builder(
			itemCount: notes.length,
			itemBuilder: (context, index) {
				final note = notes[index];
				return NoteItem(
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
										content: Text('No se pudo eliminar la nota.'),
									),
								);
							}
						}
					},
					onTap: () async {
						await Navigator.of(context).push(
							MaterialPageRoute<void>(
								builder: (_) => CreateNoteScreen(initialNote: note),
							),
						);
						ref.invalidate(notesProvider);
					},
				);
			},
		);
	}
}
