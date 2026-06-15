import 'package:flutter/foundation.dart';

/// Lightweight structured logger scoped to a single component.
///
/// In debug builds, emits to the platform console via [debugPrint].
/// In release builds, all calls are no-ops by default.
///
/// Wire up a remote crash-reporter (Sentry, Firebase Crashlytics, etc.)
/// by replacing the body of [_emit] with your reporting SDK calls when
/// preparing a production release.
class AppLogger {
  const AppLogger(this._tag);

  final String _tag;

  /// Informational event – e.g., successful operation or state change.
  void info(String message, [Object? extra]) =>
      _emit('INFO ', message, extra);

  /// Non-fatal anomaly – something unexpected but recoverable.
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _emit('WARN ', message, error);
    if (stackTrace != null) _emit('WARN ', 'StackTrace', stackTrace);
  }

  /// Fatal or data-corrupting error.  Wire to crash reporter in release.
  void error(String message, Object err, [StackTrace? stackTrace]) {
    _emit('ERROR', message, err);
    if (stackTrace != null) _emit('ERROR', 'StackTrace', stackTrace);
  }

  /// Verbose tracing – only emitted in debug builds.
  void debug(String message, [Object? extra]) {
    if (kDebugMode) _emit('DEBUG', message, extra);
  }

  void _emit(String level, String message, Object? extra) {
    if (!kDebugMode) return; // swap with remote reporter for production
    final ts = DateTime.now().toIso8601String();
    final line = '[$ts][$level][$_tag] $message';
    debugPrint(extra == null ? line : '$line | $extra');
  }
}
