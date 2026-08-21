import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/core/constants/repeat_type.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';
import 'package:nuvora/features/tasks/domain/services/task_recurrence_calculator.dart';

void main() {
	group('TaskRecurrenceCalculator.nextOccurrence', () {
		test('returns null for none', () {
			final result = TaskRecurrenceCalculator.nextOccurrence(
				repeatType: RepeatType.none,
				fromDate: DateTime(2026, 1, 15),
			);

			expect(result, isNull);
		});

		test('adds one day for daily', () {
			final result = TaskRecurrenceCalculator.nextOccurrence(
				repeatType: RepeatType.daily,
				fromDate: DateTime(2026, 1, 15, 18, 30),
			);

			expect(result, DateTime(2026, 1, 16));
		});

		test('adds seven days for weekly', () {
			final result = TaskRecurrenceCalculator.nextOccurrence(
				repeatType: RepeatType.weekly,
				fromDate: DateTime(2026, 1, 15, 18, 30),
			);

			expect(result, DateTime(2026, 1, 22));
		});

		test('keeps day for monthly when available', () {
			final result = TaskRecurrenceCalculator.nextOccurrence(
				repeatType: RepeatType.monthly,
				fromDate: DateTime(2026, 1, 15),
			);

			expect(result, DateTime(2026, 2, 15));
		});

		test('clamps day for monthly when next month is shorter', () {
			final result = TaskRecurrenceCalculator.nextOccurrence(
				repeatType: RepeatType.monthly,
				fromDate: DateTime(2026, 1, 31),
			);

			expect(result, DateTime(2026, 2, 28));
		});
	});

	group('TaskRecurrenceCalculator.nextOccurrenceForTask', () {
		test('uses dueDate when available', () {
			final task = Task(
				id: 'task-1',
				title: 'Monthly task',
				createdAt: DateTime(2026, 1, 10),
				dueDate: DateTime(2026, 1, 31),
				isCompleted: false,
				priority: Priority.medium,
				repeatType: RepeatType.monthly,
			);

			final result = TaskRecurrenceCalculator.nextOccurrenceForTask(task);

			expect(result, DateTime(2026, 2, 28));
		});

		test('uses createdAt when dueDate is null', () {
			final task = Task(
				id: 'task-2',
				title: 'Weekly task',
				createdAt: DateTime(2026, 1, 10),
				isCompleted: false,
				priority: Priority.medium,
				repeatType: RepeatType.weekly,
			);

			final result = TaskRecurrenceCalculator.nextOccurrenceForTask(task);

			expect(result, DateTime(2026, 1, 17));
		});

		test('uses baseDate when provided', () {
			final task = Task(
				id: 'task-3',
				title: 'Daily task',
				createdAt: DateTime(2026, 1, 1),
				isCompleted: false,
				priority: Priority.medium,
				repeatType: RepeatType.daily,
			);

			final result = TaskRecurrenceCalculator.nextOccurrenceForTask(
				task,
				baseDate: DateTime(2026, 3, 9),
			);

			expect(result, DateTime(2026, 3, 10));
		});
	});
}
