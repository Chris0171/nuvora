import 'package:nuvora/features/reminders/domain/entities/reminder.dart';

abstract class ReminderDataSource {
	Future<List<Reminder>> getReminders({
		DateTime? from,
		DateTime? to,
	});

	Future<Reminder?> getReminderById(String reminderId);
	Future<void> createReminder(Reminder reminder);
	Future<void> updateReminder(Reminder reminder);
	Future<void> deleteReminder(String reminderId);
	Future<void> setReminderActive({
		required String reminderId,
		required bool isActive,
	});
}
