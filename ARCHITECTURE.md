# Nuvora Architecture Guide

This document provides guidelines for developing new features following the established architectural patterns.

## Overview

Nuvora follows **Clean Architecture** with strict layer separation:

```
domain/          → Business logic, entities, repository contracts
data/            → Repository implementations, datasources, persistence
application/     → Controllers, Riverpod providers, business use cases
presentation/    → UI screens, widgets, state management bindings
```

---

## Core Infrastructure

### Database Layer (`lib/core/database/`)

All SQLite datasources inherit from `SqliteDatasourceBase` to eliminate boilerplate and ensure consistency.

#### SqliteDatasourceBase

**Purpose:** Handles platform-aware database factory resolution, connection lifecycle, and migration hooks.

**What it provides:**
- `db` getter: Lazy-initialized, singleton database connection with concurrency guards
- Platform detection: Android/iOS (native sqflite) vs Desktop (FFI)
- Schema migration hooks: `onCreateSchema()`, `onUpgradeSchema()`
- Automatic logging

**What it does NOT provide:**
- Entity serialization (`toMap()`, `fromMap()`)
- CRUD operations
- Domain-specific logic

**Usage in new feature:**

```dart
class SQLiteRemindersDataSource extends SqliteDatasourceBase 
    implements ReminderDataSource {
  
  SQLiteRemindersDataSource({
    super.databaseFactory,
    super.databasePath,
  });

  @override
  String get databaseName => 'nuvora_reminders.db';
  
  @override
  int get databaseVersion => 1;
  
  @override
  String get tableName => 'reminders';

  @override
  Future<void> onCreateSchema(Database db, int version) async {
    // Schema definition here
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        ...
      )
    ''');
  }

  @override
  Future<void> onUpgradeSchema(Database db, int oldVersion, int newVersion) async {
    // Migration logic here
  }

  // CRUD operations below
  @override
  Future<List<Reminder>> getReminders() async {
    final database = await db;
    final rows = await database.query(tableName);
    return rows.map(_reminderFromMap).toList();
  }
  
  // ... other CRUD methods
}
```

---

## Feature Structure

Each feature must follow this exact structure:

### 1. Domain Layer (`lib/features/<feature>/domain/`)

```
domain/
├── entities/
│   ├── <entity>.dart          # Immutable entity with copyWith
│   └── <entity_stats>.dart    # Optional: aggregation models
├── repositories/
│   └── <entity>_repository.dart  # Abstract interface (no implementation)
```

**Entity Requirements:**
- Immutable (@immutable annotation)
- copyWith() method for updates
- All fields with meaningful defaults
- Supports soft-delete (deletedAt field)
- Has updatedAt timestamp

**Repository Requirements:**
- Pure abstract interface
- No implementation logic
- Operations must support domain invariants

Example:

```dart
import 'package:flutter/foundation.dart';

@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.taskId,
    required this.scheduledTime,
    required this.type,
    this.enabled = true,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String taskId;
  final DateTime scheduledTime;
  final ReminderType type;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder copyWith({...}) => Reminder(...);
}

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
  Future<void> createReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String reminderId);
}
```

### 2. Data Layer (`lib/features/<feature>/data/`)

```
data/
├── datasources/
│   ├── <entity>_datasource.dart         # Abstract interface
│   └── sqlite_<entity>_datasource.dart  # Concrete implementation
└── repositories/
    └── <entity>_repository_impl.dart    # Repository implementation
```

**DataSource Requirements:**
- Mirror repository interface exactly
- Handle CRUD operations
- Implement domain exceptions
- All operations are transactional

**Repository Implementation:**
- Normalizes data (UUID migration, timestamp stamping)
- Validates domain invariants
- Logs operations
- Delegates to datasource

Example:

```dart
class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl({required this.dataSource});
  
  final ReminderDataSource dataSource;
  static const Uuid _uuid = Uuid();
  static final AppLogger _log = AppLogger('ReminderRepository');

  @override
  Future<void> createReminder(Reminder reminder) async {
    final normalized = reminder.copyWith(
      id: _shouldReplaceId(reminder.id) ? _uuid.v4() : reminder.id,
      updatedAt: DateTime.now(),
    );
    _validate(normalized);
    await dataSource.createReminder(normalized);
    _log.debug('Reminder created', normalized.id);
  }

  void _validate(Reminder reminder) {
    if (reminder.taskId.trim().isEmpty) {
      throw const ReminderValidationException('taskId cannot be empty');
    }
  }
}
```

### 3. Application Layer (`lib/features/<feature>/application/`)

```
application/
└── controllers/
    ├── <entity>_controller.dart       # Pure business logic orchestrator
    └── <entity>_provider.dart         # Riverpod DI setup
```

**Controller Requirements:**
- Thin orchestration layer
- Delegates to repository
- No Riverpod dependencies
- All methods are async and delegated

**Provider Requirements:**
- Dependency injection chain: DataSource → Repository → Controller → FutureProvider
- Export only necessary providers
- StateProviders for local UI state (filters, search queries)

Example:

```dart
class ReminderController {
  const ReminderController({required this.repository});
  
  final ReminderRepository repository;

  Future<List<Reminder>> loadReminders() => repository.getReminders();
  
  Future<void> createReminder(Reminder reminder) => 
    repository.createReminder(reminder);
  
  Future<void> deleteReminder(String id) => 
    repository.deleteReminder(id);
}

// Providers
final reminderDataSourceProvider = Provider<ReminderDataSource>(
  (ref) => SQLiteReminderDataSource(),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepositoryImpl(
    dataSource: ref.read(reminderDataSourceProvider),
  ),
);

final reminderControllerProvider = Provider<ReminderController>(
  (ref) => ReminderController(
    repository: ref.read(reminderRepositoryProvider),
  ),
);

final remindersProvider = FutureProvider<List<Reminder>>(
  (ref) => ref.read(reminderControllerProvider).loadReminders(),
);
```

### 4. Presentation Layer (`lib/features/<feature>/presentation/`)

```
presentation/
├── screens/
│   ├── <entity>_list_screen.dart
│   └── create_<entity>_screen.dart
└── widgets/
    └── <entity>_item.dart
```

**Screen Requirements:**
- Use ConsumerWidget/ConsumerStatefulWidget for Riverpod
- Watch providers for state
- Handle loading/error/data states explicitly
- Show SnackBars for errors
- Use loading guards to prevent double-submit
- Use ValueKey(entity.id) for list items

**Widget Requirements:**
- Pure, composable UI components
- Accept callbacks for user actions
- No direct repository access

Example:

```dart
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: remindersAsync.when(
        data: (reminders) => ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return ReminderItem(
              key: ValueKey(reminder.id),
              reminder: reminder,
              onDelete: () async {
                try {
                  await ref.read(reminderControllerProvider)
                    .deleteReminder(reminder.id);
                  ref.invalidate(remindersProvider);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete')),
                    );
                  }
                }
              },
            );
          },
        ),
        loading: () => const CircularProgressIndicator(),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## Testing Patterns

Each layer must be tested independently:

### Unit Tests (`domain/` and `application/`)
- Test business logic in isolation
- Use fake implementations of dependencies
- Test error paths

### Integration Tests (`data/`)
- Test datasource with real SQLite (in-memory)
- Test repository with fake datasource
- Test migrations and schema

### Widget Tests (`presentation/`)
- Test UI rendering
- Test user interactions
- Mock providers with ProviderContainer

### Benchmark Tests (`data/`)
- Test performance with 10k+ records
- Verify indexes work correctly
- Measure query times

Example:

```dart
void main() {
  late FakeReminderRepository repo;
  late ReminderController controller;

  setUp(() {
    repo = FakeReminderRepository();
    controller = ReminderController(repository: repo);
  });

  test('loadReminders delegates to repository', () async {
    repo.reminders = [_reminder(id: '1')];
    final result = await controller.loadReminders();
    expect(result, hasLength(1));
  });

  test('propagates repository errors', () async {
    repo.throwOnCreate = Exception('fail');
    await expectLater(
      controller.createReminder(_reminder()),
      throwsException,
    );
  });
}
```

---

## Error Handling

### Exception Hierarchy

Each feature defines its own exception hierarchy:

```dart
class ReminderException implements Exception {
  const ReminderException(this.message);
  final String message;
}

class ReminderNotFoundException extends ReminderException {
  const ReminderNotFoundException(String id) : super('Reminder not found: $id');
}

class ReminderValidationException extends ReminderException {
  const ReminderValidationException(super.message);
}
```

### Datasource Error Handling

Datasources must convert low-level errors to domain exceptions:

```dart
try {
  await database.insert(tableName, map);
} on DatabaseException catch (e) {
  if (e.isUniqueConstraintError()) {
    throw ReminderAlreadyExistsException(reminder.id);
  }
  rethrow;
}
```

---

## Logging

Use the structured logger provided by `AppLogger`:

```dart
final AppLogger _log = AppLogger('ReminderRepository');

_log.debug('Creating reminder', reminderId);    // Low-level operation
_log.info('Reminder created', reminderId);      // High-level event
_log.warning('Stale reminder', reminderId);     // Potential issue
_log.error('Failed to sync', error);            // Error event
```

---

## Code Organization Rules

✅ **DO:**
- Keep layers strictly separated
- Use dependency injection for all dependencies
- Write immutable entities
- Test at multiple layers
- Use feature-specific exceptions
- Implement soft-delete for all entities
- Add indexes to datasources for performance

❌ **DON'T:**
- Access repositories from presentation layer (use controllers)
- Put business logic in UI
- Share repository implementations between features
- Create generic base classes unless used by 3+ features
- Mix domain logic with persistence logic
- Put timestamps in IDs

---

## Adding a New Feature: Step-by-Step

1. **Define domain** (`lib/features/<feature>/domain/`)
   - Create entity with immutable, copyWith, timestamps
   - Define repository interface

2. **Implement data layer** (`lib/features/<feature>/data/`)
   - Create datasource interface (same as repository)
   - Implement SQLiteDataSource extending SqliteDatasourceBase
   - Implement repository adding validation/normalization

3. **Create application layer** (`lib/features/<feature>/application/`)
   - Create controller (thin delegation)
   - Set up Riverpod providers (DI chain)

4. **Build presentation** (`lib/features/<feature>/presentation/`)
   - Create screens and widgets
   - Use ConsumerWidget, ref.watch, error handling

5. **Test all layers**
   - Unit tests for entities and controllers
   - Integration tests for datasource
   - Widget tests for screens
   - Benchmark tests for performance

6. **Document if patterns diverge**
   - If your feature needs different patterns, update this guide

---

## FAQ

**Q: Should I inherit from BaseSomething?**  
A: Only from `SqliteDatasourceBase`. Base repositories or controllers are premature abstraction.

**Q: Can features share code?**  
A: No. Each feature is independent. Use `lib/core/` for truly shared infrastructure only.

**Q: How do I handle complex queries?**  
A: Keep them in the datasource. If they're complex, add a helper method.

**Q: Can I put validation in the UI?**  
A: UX validation yes (form validation). Domain validation always in repository/datasource.

**Q: How many providers do I need?**  
A: Minimum: DataSource, Repository, Controller, FutureProvider. Add more for filters, search queries.

