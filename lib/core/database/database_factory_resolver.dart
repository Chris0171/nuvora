import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Resolves the appropriate DatabaseFactory for the current platform.
///
/// - Android/iOS: Uses native sqflite
/// - Desktop (Linux, Windows, macOS): Uses FFI implementation
class DatabaseFactoryResolver {
  static DatabaseFactory? _cached;

  /// Returns the resolved DatabaseFactory for the current platform.
  static Future<DatabaseFactory> resolve({
    DatabaseFactory? injected,
  }) async {
    if (injected != null) {
      return injected;
    }

    if (_cached != null) {
      return _cached!;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      _cached = databaseFactory;
    } else {
      sqfliteFfiInit();
      _cached = databaseFactoryFfi;
    }

    return _cached!;
  }
}
