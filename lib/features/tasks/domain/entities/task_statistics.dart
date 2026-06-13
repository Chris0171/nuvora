class TaskStatistics {
	const TaskStatistics({
		required this.completedToday,
		required this.pendingTasks,
		required this.streak,
	});

	final int completedToday;
	final int pendingTasks;
	final int streak;
}
