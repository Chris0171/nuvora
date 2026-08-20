import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/features/reminders/application/controllers/reminder_controller.dart';
import 'package:nuvora/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:nuvora/features/reminders/data/datasources/sqlite_reminder_datasource.dart';
import 'package:nuvora/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';
import 'package:nuvora/features/reminders/domain/repositories/reminder_repository.dart';

final reminderDataSourceProvider = Provider<ReminderDataSource>((ref) {
	return SQLiteReminderDataSource();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
	return ReminderRepositoryImpl(
		dataSource: ref.read(reminderDataSourceProvider),
	);
});

final reminderControllerProvider = Provider<ReminderController>((ref) {
	return ReminderController(repository: ref.read(reminderRepositoryProvider));
});

final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
	return ref.read(reminderControllerProvider).loadReminders();
});
