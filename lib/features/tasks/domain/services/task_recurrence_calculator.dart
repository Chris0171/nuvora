import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class TaskRecurrenceCalculator {
	const TaskRecurrenceCalculator._();

	static DateTime? nextOccurrence({
		required RepeatType repeatType,
		required DateTime fromDate,
	}) {
		switch (repeatType) {
			case RepeatType.none:
				return null;
			case RepeatType.daily:
				return _dateOnly(fromDate).add(const Duration(days: 1));
			case RepeatType.weekly:
				return _dateOnly(fromDate).add(const Duration(days: 7));
			case RepeatType.monthly:
				return _nextMonthly(_dateOnly(fromDate));
		}
	}

	static DateTime? nextOccurrenceForTask(
		Task task, {
		DateTime? baseDate,
	}) {
		final DateTime from = baseDate ?? task.dueDate ?? task.createdAt;
		return nextOccurrence(repeatType: task.repeatType, fromDate: from);
	}

	static DateTime _dateOnly(DateTime value) {
		return DateTime(value.year, value.month, value.day);
	}

	static DateTime _nextMonthly(DateTime fromDate) {
		final int targetYear = fromDate.month == 12 ? fromDate.year + 1 : fromDate.year;
		final int targetMonth = fromDate.month == 12 ? 1 : fromDate.month + 1;
		final int maxDayInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
		final int day = fromDate.day > maxDayInMonth ? maxDayInMonth : fromDate.day;
		return DateTime(targetYear, targetMonth, day);
	}
}
