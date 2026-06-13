import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/reminders/application/controllers/reminder_controller.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';

final reminderControllerProvider = Provider<ReminderController>((ref) {
	return const ReminderController();
});

final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
	return ref.read(reminderControllerProvider).loadReminders();
});
