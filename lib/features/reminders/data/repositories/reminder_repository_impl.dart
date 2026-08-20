import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/core/utils/app_logger.dart';
import 'package:nuvora/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';
import 'package:nuvora/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:uuid/uuid.dart';

class ReminderRepositoryImpl implements ReminderRepository {
	ReminderRepositoryImpl({required this.dataSource});

	final ReminderDataSource dataSource;
	static const Uuid _uuid = Uuid();
	static final AppLogger _log = AppLogger('ReminderRepository');

	@override
	Future<List<Reminder>> getReminders({
		DateTime? from,
		DateTime? to,
	}) async {
		try {
			return await dataSource.getReminders(from: from, to: to);
		} on ReminderException {
			rethrow;
		} catch (_) {
			throw const ReminderStorageException('Failed to load reminders');
		}
	}

	@override
	Future<Reminder?> getReminderById(String reminderId) async {
		try {
			return await dataSource.getReminderById(reminderId);
		} on ReminderException {
			rethrow;
		} catch (_) {
			throw const ReminderStorageException('Failed to load reminder');
		}
	}

	@override
	Future<void> createReminder(Reminder reminder) async {
		final now = DateTime.now();
		final replaceId = _shouldReplaceId(reminder.id);
		final newId = replaceId ? _uuid.v4() : reminder.id;

		if (replaceId) {
			_log.debug('Replaced legacy id with UUID v4', newId);
		}

		final normalized = reminder.copyWith(
			id: newId,
			updatedAt: now,
		);
		_validate(normalized);

		try {
			await dataSource.createReminder(normalized);
			_log.debug('Reminder created', newId);
		} on ReminderException {
			rethrow;
		} catch (_) {
			throw const ReminderStorageException('Failed to create reminder');
		}
	}

	@override
	Future<void> updateReminder(Reminder reminder) async {
		final normalized = reminder.copyWith(updatedAt: DateTime.now());
		_validate(normalized);

		try {
			await dataSource.updateReminder(normalized);
			_log.debug('Reminder updated', reminder.id);
		} on ReminderException {
			rethrow;
		} catch (_) {
			throw const ReminderStorageException('Failed to update reminder');
		}
	}

	@override
	Future<void> deleteReminder(String reminderId) async {
		try {
			await dataSource.deleteReminder(reminderId);
			_log.debug('Reminder soft-deleted', reminderId);
		} on ReminderException {
			rethrow;
		} catch (_) {
			throw const ReminderStorageException('Failed to delete reminder');
		}
	}

	@override
	Future<void> setReminderActive({
		required String reminderId,
		required bool isActive,
	}) async {
		try {
			await dataSource.setReminderActive(
				reminderId: reminderId,
				isActive: isActive,
			);
		} on ReminderException {
			rethrow;
		} catch (_) {
			throw const ReminderStorageException('Failed to update reminder status');
		}
	}

	void _validate(Reminder reminder) {
		if (reminder.title.trim().isEmpty) {
			throw const ReminderValidationException('Title cannot be empty');
		}
	}

	bool _shouldReplaceId(String id) {
		if (id.trim().isEmpty) {
			return true;
		}

		return RegExp(r'^\d{10,}$').hasMatch(id);
	}
}
