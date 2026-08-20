import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/reminder_type.dart';
import 'package:nuvora/features/reminders/application/controllers/reminder_controller.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';
import 'package:nuvora/features/reminders/domain/repositories/reminder_repository.dart';

class _FakeReminderRepository implements ReminderRepository {
  final List<Reminder> reminders = [];
  Reminder? lastCreated;
  Reminder? lastUpdated;
  String? lastDeletedId;
  ({String reminderId, bool isActive})? lastActivation;
  ({DateTime? from, DateTime? to})? lastRange;
  String? lastLookupId;
  Reminder? lookupResult;

  Exception? throwOnCreate;
  Exception? throwOnUpdate;
  Exception? throwOnDelete;
  Exception? throwOnActivation;
  Exception? throwOnLoad;
  Exception? throwOnLookup;

  @override
  Future<void> createReminder(Reminder reminder) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    lastCreated = reminder;
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    if (throwOnDelete != null) throw throwOnDelete!;
    lastDeletedId = reminderId;
  }

  @override
  Future<Reminder?> getReminderById(String reminderId) async {
    if (throwOnLookup != null) throw throwOnLookup!;
    lastLookupId = reminderId;
    return lookupResult;
  }

  @override
  Future<List<Reminder>> getReminders({DateTime? from, DateTime? to}) async {
    if (throwOnLoad != null) throw throwOnLoad!;
    lastRange = (from: from, to: to);
    return List.unmodifiable(reminders);
  }

  @override
  Future<void> setReminderActive({
    required String reminderId,
    required bool isActive,
  }) async {
    if (throwOnActivation != null) throw throwOnActivation!;
    lastActivation = (reminderId: reminderId, isActive: isActive);
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    if (throwOnUpdate != null) throw throwOnUpdate!;
    lastUpdated = reminder;
  }
}

Reminder _reminder({
  String id = 'rem-1',
  String title = 'Reminder',
  bool isActive = true,
}) {
  return Reminder(
    id: id,
    title: title,
    scheduledAt: DateTime(2026, 8, 20, 14),
    type: ReminderType.task,
    isActive: isActive,
    createdAt: DateTime(2026, 8, 20, 10),
  );
}

void main() {
  late _FakeReminderRepository repo;
  late ReminderController controller;

  setUp(() {
    repo = _FakeReminderRepository();
    controller = ReminderController(repository: repo);
  });

  test('loadReminders delegates date filters', () async {
    repo.reminders.add(_reminder());
    final from = DateTime(2026, 8, 20);
    final to = from.add(const Duration(days: 1));

    final result = await controller.loadReminders(from: from, to: to);

    expect(result, hasLength(1));
    expect(repo.lastRange?.from, from);
    expect(repo.lastRange?.to, to);
  });

  test('getReminderById delegates lookup', () async {
    repo.lookupResult = _reminder(id: 'lookup');
    final result = await controller.getReminderById('lookup');
    expect(repo.lastLookupId, 'lookup');
    expect(result?.id, 'lookup');
  });

  test('createReminder delegates', () async {
    final reminder = _reminder();
    await controller.createReminder(reminder);
    expect(repo.lastCreated?.id, reminder.id);
  });

  test('updateReminder delegates', () async {
    final reminder = _reminder(id: 'u1');
    await controller.updateReminder(reminder);
    expect(repo.lastUpdated?.id, 'u1');
  });

  test('deleteReminder delegates id', () async {
    await controller.deleteReminder('delete-me');
    expect(repo.lastDeletedId, 'delete-me');
  });

  test('setReminderActive delegates activate', () async {
    await controller.setReminderActive(reminderId: 'r1', isActive: true);
    expect(repo.lastActivation?.reminderId, 'r1');
    expect(repo.lastActivation?.isActive, isTrue);
  });

  test('setReminderActive delegates deactivate', () async {
    await controller.setReminderActive(reminderId: 'r2', isActive: false);
    expect(repo.lastActivation?.isActive, isFalse);
  });

  test('propagates create errors', () async {
    repo.throwOnCreate = Exception('create fail');
    await expectLater(controller.createReminder(_reminder()), throwsException);
  });

  test('propagates update errors', () async {
    repo.throwOnUpdate = Exception('update fail');
    await expectLater(controller.updateReminder(_reminder()), throwsException);
  });

  test('propagates delete errors', () async {
    repo.throwOnDelete = Exception('delete fail');
    await expectLater(controller.deleteReminder('x'), throwsException);
  });

  test('propagates activation errors', () async {
    repo.throwOnActivation = Exception('toggle fail');
    await expectLater(
      controller.setReminderActive(reminderId: 'x', isActive: true),
      throwsException,
    );
  });
}