class NotificationData {
	const NotificationData({
		required this.notificationId,
		required this.title,
		required this.body,
		required this.scheduledDate,
		required this.isRecurring,
	});

	final int notificationId;
	final String title;
	final String body;
	final DateTime scheduledDate;
	final bool isRecurring;
}
