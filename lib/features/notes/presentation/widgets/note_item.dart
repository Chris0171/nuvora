import 'package:flutter/material.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';

class NoteItem extends StatelessWidget {
	const NoteItem({
		super.key,
		required this.note,
		this.onTap,
		this.onDelete,
	});

	final Note note;
	final VoidCallback? onTap;
	final VoidCallback? onDelete;

	@override
	Widget build(BuildContext context) {
		return ListTile(
			title: Text(note.title),
			subtitle: Text(
				note.content,
				maxLines: 2,
				overflow: TextOverflow.ellipsis,
			),
			trailing: IconButton(
				onPressed: onDelete,
				icon: const Icon(Icons.delete_outline),
			),
			onTap: onTap,
		);
	}
}
