import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/theme/app_design_system.dart';
import 'package:nuvora/core/widgets/app_feedback.dart';
import 'package:nuvora/core/widgets/app_motion.dart';
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
	late bool _isPinned;
	late bool _isArchived;
	bool _isSaving = false;

	bool get _isEdit => widget.initialNote != null;

	@override
	void initState() {
		super.initState();
		_isPinned = widget.initialNote?.isPinned ?? false;
		_isArchived = widget.initialNote?.archived ?? false;
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
		if (!_isEdit) {
			HapticFeedback.lightImpact();
		}

		final DateTime now = DateTime.now();
		final Note note = (widget.initialNote ??
				Note(
					id: DateTime.now().microsecondsSinceEpoch.toString(),
					title: '',
					content: '',
					createdAt: now,
					isPinned: _isPinned,
					archived: _isArchived,
				))
			.copyWith(
				title: _titleController.text.trim(),
				content: _contentController.text.trim(),
				isPinned: _isPinned,
				archived: _isArchived,
				updatedAt: now,
			);

		try {
			if (_isEdit) {
				await ref.read(noteControllerProvider).updateNote(note);
			} else {
				await ref.read(noteControllerProvider).createNote(note);
			}
			ref.invalidate(notesProvider);
			ref.invalidate(activeNotesProvider);
			ref.invalidate(archivedNotesProvider);
			if (mounted) Navigator.of(context).pop(true);
		} catch (_) {
			if (mounted) {
				AppFeedback.showSnackBar(
					context,
					_isEdit ? 'Could not update note' : 'Could not save note',
				);
			}
		} finally {
			if (mounted) setState(() => _isSaving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text(_isEdit ? 'Edit Note' : 'New Note'),
				titleTextStyle: AppTypography.headlineLarge,
				actions: [
					if (_isEdit)
						IconButton(
							icon: Icon(_isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
							color: AppColors.textSecondary,
							tooltip: _isArchived ? 'Unarchive note' : 'Archive note',
							onPressed: () => setState(() => _isArchived = !_isArchived),
						),
					IconButton(
						icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
						color: _isPinned ? AppColors.warning : AppColors.textSecondary,
						tooltip: _isPinned ? 'Unpin note' : 'Pin note',
						onPressed: () => setState(() => _isPinned = !_isPinned),
					),
				],
			),
			body: SingleChildScrollView(
				child: Padding(
					padding: const EdgeInsets.all(AppSpacing.lg),
					child: Form(
						key: _formKey,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								// Title Field
								Text(
									'Title',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
								TextFormField(
									controller: _titleController,
									decoration: InputDecoration(
										hintText: 'Enter note title',
										prefixIcon: const Icon(Icons.title, color: AppColors.primary),
									),
									style: AppTypography.bodyMedium,
									validator: (value) {
										if (value == null || value.trim().isEmpty) {
											return 'Title is required';
										}
										return null;
									},
								),
								const SizedBox(height: AppSpacing.xl),
								// Content Field
								Text(
									'Content',
									style: AppTypography.labelLarge.copyWith(
										color: AppColors.textPrimary,
									),
								),
								const SizedBox(height: AppSpacing.md),
								TextFormField(
									controller: _contentController,
									minLines: 5,
									maxLines: 15,
									decoration: InputDecoration(
										hintText: 'Write your note...',
										prefixIcon: const Icon(Icons.description, color: AppColors.primary),
										alignLabelWithHint: true,
									),
									style: AppTypography.bodyMedium,
									validator: (value) {
										if (value == null || value.trim().isEmpty) {
											return 'Content is required';
										}
										return null;
									},
								),
								const SizedBox(height: AppSpacing.xxl),
								// Save Button
								SizedBox(
									width: double.infinity,
									height: 56,
									child: ElevatedButton(
										onPressed: _isSaving ? null : _save,
										style: ElevatedButton.styleFrom(
											elevation: _isSaving ? 0 : AppElevation.sm,
											disabledBackgroundColor: AppColors.disabledBackground,
											disabledForegroundColor: AppColors.textTertiary,
										),
										child: AnimatedSwitcher(
											duration: AppMotion.shortDuration,
											switchInCurve: AppMotion.curve,
											switchOutCurve: AppMotion.curve,
											child: _isSaving
													? const SizedBox(
														key: ValueKey('note-saving'),
														height: 24,
														width: 24,
														child: CircularProgressIndicator(
															strokeWidth: 2.5,
															valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
														),
													)
													: Text(
														key: ValueKey(_isEdit ? 'note-update-label' : 'note-create-label'),
														_isEdit ? 'Update Note' : 'Create Note',
														style: AppTypography.labelLarge,
													),
										),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}

