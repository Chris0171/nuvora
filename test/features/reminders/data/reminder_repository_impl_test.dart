import 'package:flutter_test/flutter_test.dart';
import 'package:nuvora/core/constants/reminder_type.dart';
import 'package:nuvora/core/errors/app_error.dart';
import 'package:nuvora/features/reminders/data/datasources/reminder_local_datasource.dart';
import 'package:nuvora/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:nuvora/features/reminders/domain/entities/reminder.dart';

class _FakeReminderDataSource implements ReminderDataSource {
  final List<Reminder> stored = [];
  Reminder? lastCreated;
  Reminder? lastUpdated;
  String? lastDeletedId;
  ({String reminderId, bool isActive})? lastActivation;
  ({DateTime? from, DateTime? to})? lastRange;
  String? lastLookupId;
  Reminder? lookupResult;

  Object? throwOnLoad;
  Object? throwOnLookup;
  Object? throwOnCreate;
  Object? throwOnUpdate;
  Object? throwOnDelete;
  Object? throwOnActivation;

  @override
  Future<void> createReminder(Reminder reminder) async {
    if (throwOnCreate != null) throw throwOnCreate!;
    lastCreated = reminder;
    stored.add(reminder);
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
    return List.unmodifiable(stored);
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

final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

Reminder _reminder({
  String id = 'legacy',
  String title = 'Reminder',
}) {
  return Reminder(
    id: id,
    title: title,
    scheduledAt: DateTime(2026, 8, 21, 8),
    type: ReminderType.task,
    isActive: true,
    createdAt: DateTime(2026, 8, 20, 10),
  );
}

void main() {
  late _FakeReminderDataSource ds;
  late ReminderRepositoryImpl repo;

  setUp(() {
    ds = _FakeReminderDataSource();
    repo = ReminderRepositoryImpl(dataSource: ds);
  });

  test('getReminders delegates range filters', () async {
    final from = DateTime(2026, 8, 20);
    final to = from.add(const Duration(days: 1));

    await repo.getReminders(from: from, to: to);

    expect(ds.lastRange?.from, from);
    expect(ds.lastRange?.to, to);
  });

  test('getReminderById delegates lookup', () async {
    ds.lookupResult = _reminder(id: 'r1');
    final result = await repo.getReminderById('r1');
    expect(ds.lastLookupId, 'r1');
    expect(result?.id, 'r1');
  });

  test('createReminder replaces legacy id with uuid', () async {
    await repo.createReminder(_reminder(id: '1718351234567890'));
    expect(ds.lastCreated, isNotNull);
    expect(ds.lastCreated!.id, matches(_uuidRegex));
  });

  test('createReminder keeps valid non-legacy id', () async {
    await repo.createReminder(_reminder(id: 'custom-id-1'));
    expect(ds.lastCreated!.id, 'custom-id-1');
  });

  test('createReminder validates non-empty title', () async {
    await expectLater(
      repo.createReminder(_reminder(title: '   ')),
      throwsA(isA<ReminderValidationException>()),
    );
  });

  test('createReminder stamps updatedAt', () async {
    final before = DateTime.now().subtract(const Duration(milliseconds: 50));
    await repo.createReminder(_reminder());
    final after = DateTime.now().add(const Duration(milliseconds: 50));
    expect(ds.lastCreated!.updatedAt.isAfter(before), isTrue);
    expect(ds.lastCreated!.updatedAt.isBefore(after), isTrue);
  });

  test('updateReminder stamps updatedAt', () async {
    final original = _reminder(id: 'u1');
    await repo.updateReminder(original);
    expect(ds.lastUpdated, isNotNull);
    expect(ds.lastUpdated!.updatedAt.isAtSameMomentAs(original.updatedAt), isFalse);
  });

  test('deleteReminder delegates id', () async {
    await repo.deleteReminder('del-1');
    expect(ds.lastDeletedId, 'del-1');
  });

  test('setReminderActive delegates params', () async {
    await repo.setReminderActive(reminderId: 'r1', isActive: false);
    expect(ds.lastActivation?.reminderId, 'r1');
    expect(ds.lastActivation?.isActive, isFalse);
  });

  test('passes through domain exceptions', () async {
    ds.throwOnDelete = const ReminderNotFoundException('x');
    await expectLater(
      repo.deleteReminder('x'),
      throwsA(isA<ReminderNotFoundException>()),
    );
  });

  test('translates infrastructure errors on create', () async {
    ds.throwOnCreate = Exception('db fail');
    await expectLater(
      repo.createReminder(_reminder()),
      throwsA(isA<ReminderStorageException>()),
    );
  });

  test('translates infrastructure errors on load', () async {
    ds.throwOnLoad = Exception('db fail');
    await expectLater(
      repo.getReminders(),
      throwsA(isA<ReminderStorageException>()),
    );
  });
}