import 'package:nuvora/features/notifications/domain/entities/notification_data.dart';

class NotificationController {
	const NotificationController();

	Future<List<NotificationData>> loadNotifications() async {
		throw UnimplementedError();
	}

	Future<void> scheduleNotification(NotificationData notification) async {
		throw UnimplementedError();
	}

	Future<void> cancelNotification(int notificationId) async {
		throw UnimplementedError();
	}
}
