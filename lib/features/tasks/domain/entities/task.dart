import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';

class Task {
	const Task({
		required this.id,
		required this.title,
		this.description,
		required this.createdAt,
		this.dueDate,
		required this.isCompleted,
		required this.priority,
		this.categoryId,
		required this.repeatType,
	});

	final String id;
	final String title;
	final String? description;
	final DateTime createdAt;
	final DateTime? dueDate;
	final bool isCompleted;
	final Priority priority;
	final String? categoryId;
	final RepeatType repeatType;
}
