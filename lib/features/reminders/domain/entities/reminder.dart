import 'package:nuvora/core/constants/reminder_type.dart';

class Reminder {
	const Reminder({
		required this.id,
		required this.title,
		this.description,
		required this.scheduledAt,
		this.relatedItemId,
		required this.type,
		required this.isActive,
		required this.createdAt,
		DateTime? updatedAt,
		this.archived = false,
		this.deletedAt,
	}) : updatedAt = updatedAt ?? createdAt;

	final String id;
	final String title;
	final String? description;
	final DateTime scheduledAt;
	final String? relatedItemId;
	final ReminderType type;
	final bool isActive;
	final DateTime createdAt;
	final DateTime updatedAt;
	final bool archived;
	final DateTime? deletedAt;

	Reminder copyWith({
		String? id,
		String? title,
		String? description,
		DateTime? scheduledAt,
		String? relatedItemId,
		ReminderType? type,
		bool? isActive,
		DateTime? createdAt,
		DateTime? updatedAt,
		bool? archived,
		DateTime? deletedAt,
	}) {
		return Reminder(
			id: id ?? this.id,
			title: title ?? this.title,
			description: description ?? this.description,
			scheduledAt: scheduledAt ?? this.scheduledAt,
			relatedItemId: relatedItemId ?? this.relatedItemId,
			type: type ?? this.type,
			isActive: isActive ?? this.isActive,
			createdAt: createdAt ?? this.createdAt,
			updatedAt: updatedAt ?? this.updatedAt,
			archived: archived ?? this.archived,
			deletedAt: deletedAt ?? this.deletedAt,
		);
	}
}
