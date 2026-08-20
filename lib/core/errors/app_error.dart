/// Base exception for all domain-level task errors.
class TaskException implements Exception {
  const TaskException(this.message);

  final String message;

  @override
  String toString() => 'TaskException: $message';
}

/// Thrown when an operation targets a task that does not exist (or is
/// soft-deleted).
class TaskNotFoundException extends TaskException {
  const TaskNotFoundException(String taskId)
      : super('Task not found: $taskId');
}

/// Thrown when trying to create a task whose id already exists in the store.
class TaskAlreadyExistsException extends TaskException {
  const TaskAlreadyExistsException(String taskId)
      : super('Task already exists: $taskId');
}

/// Thrown when a Task violates a domain invariant (e.g. blank title).
class TaskValidationException extends TaskException {
  const TaskValidationException(super.message);
}

/// Base exception for all domain-level note errors.
class NoteException implements Exception {
  const NoteException(this.message);

  final String message;

  @override
  String toString() => 'NoteException: $message';
}

/// Thrown when an operation targets a note that does not exist (or is
/// soft-deleted).
class NoteNotFoundException extends NoteException {
  const NoteNotFoundException(String noteId)
      : super('Note not found: $noteId');
}

/// Thrown when trying to create a note whose id already exists in the store.
class NoteAlreadyExistsException extends NoteException {
  const NoteAlreadyExistsException(String noteId)
      : super('Note already exists: $noteId');
}

/// Thrown when a Note violates a domain invariant.
class NoteValidationException extends NoteException {
  const NoteValidationException(super.message);
}

/// Base exception for all domain-level reminder errors.
class ReminderException implements Exception {
  const ReminderException(this.message);

  final String message;

  @override
  String toString() => 'ReminderException: $message';
}

/// Thrown when an operation targets a reminder that does not exist (or is
/// soft-deleted).
class ReminderNotFoundException extends ReminderException {
  const ReminderNotFoundException(String reminderId)
      : super('Reminder not found: $reminderId');
}

/// Thrown when trying to create a reminder whose id already exists.
class ReminderAlreadyExistsException extends ReminderException {
  const ReminderAlreadyExistsException(String reminderId)
      : super('Reminder already exists: $reminderId');
}

/// Thrown when a Reminder violates a domain invariant.
class ReminderValidationException extends ReminderException {
  const ReminderValidationException(super.message);
}

/// Thrown when infrastructure-level reminder failures need translation into
/// the feature's domain boundary.
class ReminderStorageException extends ReminderException {
  const ReminderStorageException(super.message);
}

/// Base exception for all domain-level category errors.
class CategoryException implements Exception {
  const CategoryException(this.message);

  final String message;

  @override
  String toString() => 'CategoryException: $message';
}

/// Thrown when trying to create a category that already exists.
class CategoryAlreadyExistsException extends CategoryException {
  const CategoryAlreadyExistsException(String categoryName)
      : super('Category already exists: $categoryName');
}

/// Thrown when a Category violates a domain invariant.
class CategoryValidationException extends CategoryException {
  const CategoryValidationException(super.message);
}
