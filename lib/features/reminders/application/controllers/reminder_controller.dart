import 'package:nuvora/features/reminders/domain/entities/reminder.dart';
import 'package:nuvora/features/reminders/domain/repositories/reminder_repository.dart';

class ReminderController {
	ReminderController({required this.repository});

	final ReminderRepository repository;

	Future<List<Reminder>> loadReminders({
		DateTime? from,
		DateTime? to,
	}) async {
		return repository.getReminders(from: from, to: to);
	}

	Future<Reminder?> getReminderById(String reminderId) async {
		return repository.getReminderById(reminderId);
	}

	Future<void> createReminder(Reminder reminder) async {
		await repository.createReminder(reminder);
	}

	Future<void> updateReminder(Reminder reminder) async {
		await repository.updateReminder(reminder);
	}

	Future<void> deleteReminder(String reminderId) async {
		await repository.deleteReminder(reminderId);
	}

	Future<void> setReminderActive({
		required String reminderId,
		required bool isActive,
	}) async {
		await repository.setReminderActive(
			reminderId: reminderId,
			isActive: isActive,
		);
	}
}
