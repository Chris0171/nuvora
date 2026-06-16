import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/notes/application/controllers/note_provider.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

class CreateNoteScreen extends ConsumerStatefulWidget {
	const CreateNoteScreen({
		super.key,
		this.initialNote,
	});

	final Note? initialNote;

	@override
	ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
	final _formKey = GlobalKey<FormState>();
	late final TextEditingController _titleController;
	late final TextEditingController _contentController;
	bool _isSaving = false;

	bool get _isEdit => widget.initialNote != null;

	@override
	void initState() {
		super.initState();
		_titleController = TextEditingController(text: widget.initialNote?.title);
		_contentController = TextEditingController(text: widget.initialNote?.content);
	}

	@override
	void dispose() {
		_titleController.dispose();
		_contentController.dispose();
		super.dispose();
	}

	Future<void> _save() async {
		if (!_formKey.currentState!.validate() || _isSaving) {
			return;
		}

		setState(() => _isSaving = true);

		final DateTime now = DateTime.now();
		final Note note = (widget.initialNote ??
				Note(
					id: DateTime.now().microsecondsSinceEpoch.toString(),
					title: '',
					content: '',
					createdAt: now,
					isPinned: false,
				))
			.copyWith(
				title: _titleController.text.trim(),
				content: _contentController.text.trim(),
				updatedAt: now,
			);

		try {
			if (_isEdit) {
				await ref.read(noteControllerProvider).updateNote(note);
			} else {
				await ref.read(noteControllerProvider).createNote(note);
			}
			ref.invalidate(notesProvider);
			if (mounted) Navigator.of(context).pop(true);
		} catch (_) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(
							_isEdit
								? 'No se pudo actualizar la nota.'
								: 'No se pudo guardar la nota.',
						),
					),
				);
			}
		} finally {
			if (mounted) setState(() => _isSaving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text(_isEdit ? 'Editar nota' : 'Crear nota')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						children: [
							TextFormField(
								controller: _titleController,
								decoration: const InputDecoration(labelText: 'Titulo'),
								validator: (value) {
									if (value == null || value.trim().isEmpty) {
										return 'El titulo es obligatorio';
									}
									return null;
								},
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _contentController,
								maxLines: 5,
								decoration: const InputDecoration(labelText: 'Contenido'),
								validator: (value) {
									if (value == null || value.trim().isEmpty) {
										return 'El contenido es obligatorio';
									}
									return null;
								},
							),
							const SizedBox(height: 20),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									onPressed: _isSaving ? null : _save,
									child: _isSaving
											? const SizedBox(
													height: 20,
													width: 20,
													child: CircularProgressIndicator(strokeWidth: 2),
												)
											: Text(_isEdit ? 'Actualizar nota' : 'Guardar nota'),
								),
							),
						],
					),
				),
			),
		);
	}
}
