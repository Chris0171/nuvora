import 'package:nuvora/core/constants/priority.dart';
import 'package:nuvora/features/notes/domain/entities/note.dart';
import 'package:nuvora/features/tasks/domain/entities/task.dart';

class ProductivityAnalyzer {
  const ProductivityAnalyzer._();

  static double calculateFocusScore(List<Task> tasks) {
    return calculateCompletionRate(tasks);
  }

  static double calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  static Task? getRecommendedTask(List<Task> tasks) {
    final pending = tasks.where((task) => !task.isCompleted).toList();
    if (pending.isEmpty) return null;

    final highPriority = pending.where((task) {
      return task.priority == Priority.high || task.priority == Priority.urgent;
    }).toList();
    if (highPriority.isNotEmpty) {
      return _sortByUrgency(highPriority).first;
    }

    final now = DateTime.now();
    final overdue = pending.where((task) {
      return task.dueDate != null && task.dueDate!.isBefore(now);
    }).toList();
    if (overdue.isNotEmpty) {
      return _sortByUrgency(overdue).first;
    }

    return _sortByUrgency(pending).first;
  }

  static int calculateProductivityScore(List<Task> tasks, List<Note> notes) {
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final score = (completedTasks * 10) + (notes.length * 2);
    return score.clamp(0, 100);
  }

  static String getConsistencyLevel(int score) {
    if (score >= 75) return 'Excellent consistency';
    if (score >= 45) return 'Good consistency';
    return 'Low consistency';
  }

  static int getOverdueCount(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      return !task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.isBefore(now);
    }).length;
  }

  static int getPendingCount(List<Task> tasks) {
    return tasks.where((task) => !task.isCompleted).length;
  }

  static String getPriorityExplanation(Task task) {
    switch (task.priority) {
      case Priority.high:
      case Priority.urgent:
        return 'Needs attention soon';
      case Priority.medium:
        return 'Can be done later';
      case Priority.low:
        return 'Flexible';
    }
  }

  static String getRecommendedUrgencyText(Task task) {
    final now = DateTime.now();
    if (task.dueDate != null && task.dueDate!.isBefore(now)) {
      return 'Overdue task';
    }
    if (task.priority == Priority.high || task.priority == Priority.urgent) {
      return 'High impact task';
    }
    return 'Recommended for now';
  }

  static int getRecentNotesCount(List<Note> notes, {int days = 7}) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    return notes.where((note) => note.createdAt.isAfter(threshold)).length;
  }

  static List<Task> _sortByUrgency(List<Task> tasks) {
    final sorted = [...tasks];
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }
}
