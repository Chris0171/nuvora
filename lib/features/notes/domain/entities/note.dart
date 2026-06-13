class Note {
	const Note({
		required this.id,
		required this.title,
		required this.content,
		required this.createdAt,
		required this.updatedAt,
		required this.isPinned,
	});

	final String id;
	final String title;
	final String content;
	final DateTime createdAt;
	final DateTime updatedAt;
	final bool isPinned;
}
