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
