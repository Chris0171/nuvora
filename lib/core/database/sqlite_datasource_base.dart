import 'package:nuvora/core/database/database_factory_resolver.dart';
import 'package:nuvora/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Base class for SQLite datasources handling database lifecycle and factory resolution.
///
/// Subclasses must implement:
/// - [databaseName]: Unique database filename
/// - [databaseVersion]: Schema version for migrations
/// - [tableName]: Primary table name
/// - [onCreateSchema]: Schema definition (CREATE TABLE, indexes)
/// - [onUpgradeSchema]: Migration logic for version upgrades
///
/// Automatically handles:
/// - Platform-aware factory resolution (mobile vs desktop FFI)
/// - Database lazy initialization with concurrency guard
/// - Connection lifecycle management
abstract class SqliteDatasourceBase {
  SqliteDatasourceBase({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _injectedFactory = databaseFactory,
        _injectedPath = databasePath;

  final DatabaseFactory? _injectedFactory;
  final String? _injectedPath;

  Database? _database;
  Future<Database>? _openingDatabase;
  DatabaseFactory? _databaseFactory;

  /// Database filename (e.g., 'nuvora_tasks.db')
  String get databaseName;

  /// Current schema version for migrations
  int get databaseVersion;

  /// Primary table name
  String get tableName;

  /// Logger for this datasource
  AppLogger get logger => AppLogger(runtimeType.toString());

  /// Called when database is created for the first time.
  /// Implement to create schema: CREATE TABLE, indexes, etc.
  Future<void> onCreateSchema(Database db, int version);

  /// Called on database upgrade.
  /// Implement to handle migrations between versions.
  Future<void> onUpgradeSchema(Database db, int oldVersion, int newVersion);

  /// Lazily opens and caches the database connection.
  /// Handles concurrent access with a race-condition guard.
  Future<Database> get db async {
    if (_database != null) {
      return _database!;
    }

    if (_openingDatabase != null) {
      return _openingDatabase!;
    }

    _openingDatabase = _openDatabase();
    try {
      _database = await _openingDatabase!;
      return _database!;
    } finally {
      _openingDatabase = null;
    }
  }

  /// Internal method to resolve DatabaseFactory based on platform.
  Future<DatabaseFactory> get _resolvedFactory async {
    if (_databaseFactory != null) {
      return _databaseFactory!;
    }

    final factory = await DatabaseFactoryResolver.resolve(
      injected: _injectedFactory,
    );
    _databaseFactory = factory;
    return factory;
  }

  /// Opens the database with schema creation/migration.
  Future<Database> _openDatabase() async {
    final factory = await _resolvedFactory;
    final path = _injectedPath ??
        p.join(await factory.getDatabasesPath(), databaseName);

    logger.info('Opening database', path);

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onCreate: onCreateSchema,
        onUpgrade: onUpgradeSchema,
      ),
    );
  }
}
