import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';

class Task {
	const Task({
		required this.id,
		required this.title,
		this.description,
		required this.createdAt,
		DateTime? updatedAt,
		this.dueDate,
		required this.isCompleted,
		required this.priority,
		this.categoryId,
		required this.repeatType,
		this.archived = false,
		this.deletedAt,
	}) : updatedAt = updatedAt ?? createdAt;

	final String id;
	final String title;
	final String? description;
	final DateTime createdAt;
	final DateTime updatedAt;
	final DateTime? dueDate;
	final bool isCompleted;
	final Priority priority;
	final String? categoryId;
	final RepeatType repeatType;
	final bool archived;
	final DateTime? deletedAt;

	Task copyWith({
		String? id,
		String? title,
		String? description,
		DateTime? createdAt,
		DateTime? updatedAt,
		DateTime? dueDate,
		bool? isCompleted,
		Priority? priority,
		String? categoryId,
		RepeatType? repeatType,
		bool? archived,
		DateTime? deletedAt,
	}) {
		return Task(
			id: id ?? this.id,
			title: title ?? this.title,
			description: description ?? this.description,
			createdAt: createdAt ?? this.createdAt,
			updatedAt: updatedAt ?? this.updatedAt,
			dueDate: dueDate ?? this.dueDate,
			isCompleted: isCompleted ?? this.isCompleted,
			priority: priority ?? this.priority,
			categoryId: categoryId ?? this.categoryId,
			repeatType: repeatType ?? this.repeatType,
			archived: archived ?? this.archived,
			deletedAt: deletedAt ?? this.deletedAt,
		);
	}
}
