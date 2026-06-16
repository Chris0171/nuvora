class Note {
	const Note({
		required this.id,
		required this.title,
		required this.content,
		required this.createdAt,
		DateTime? updatedAt,
		required this.isPinned,
		this.archived = false,
		this.deletedAt,
	}) : updatedAt = updatedAt ?? createdAt;

	final String id;
	final String title;
	final String content;
	final DateTime createdAt;
	final DateTime updatedAt;
	final bool isPinned;
	final bool archived;
	final DateTime? deletedAt;

	Note copyWith({
		String? id,
		String? title,
		String? content,
		DateTime? createdAt,
		DateTime? updatedAt,
		bool? isPinned,
		bool? archived,
		DateTime? deletedAt,
	}) {
		return Note(
			id: id ?? this.id,
			title: title ?? this.title,
			content: content ?? this.content,
			createdAt: createdAt ?? this.createdAt,
			updatedAt: updatedAt ?? this.updatedAt,
			isPinned: isPinned ?? this.isPinned,
			archived: archived ?? this.archived,
			deletedAt: deletedAt ?? this.deletedAt,
		);
	}
}
