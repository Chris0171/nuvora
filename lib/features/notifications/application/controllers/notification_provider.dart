import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/notifications/application/controllers/notification_controller.dart';
import 'package:nuvora/features/notifications/domain/entities/notification_data.dart';

final notificationControllerProvider = Provider<NotificationController>((ref) {
	return const NotificationController();
});

final notificationsProvider = FutureProvider<List<NotificationData>>((ref) async {
	return ref.read(notificationControllerProvider).loadNotifications();
});
