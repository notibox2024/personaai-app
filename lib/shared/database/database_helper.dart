import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Singleton class để quản lý SQLite database
class DatabaseHelper {
  static const String _databaseName = 'personaai.db';
  static const int _databaseVersion = 1;
  
  static Database? _database;
  
  /// Private constructor cho singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  
  /// Get database instance với lazy initialization
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  /// Initialize database với schema creation
  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), _databaseName);
      
      if (kDebugMode) {
        print('Database path: $path');
      }
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
        onOpen: (db) async {
          // Enable foreign key constraints
          await db.execute('PRAGMA foreign_keys = ON');
          if (kDebugMode) {
            print('Database opened successfully');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
      rethrow;
    }
  }
  
  /// Create all database tables với indexes
  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Create notifications table
      await txn.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'unread',
          priority TEXT NOT NULL DEFAULT 'normal',
          created_at INTEGER NOT NULL,
          read_at INTEGER NULL,
          scheduled_at INTEGER NULL,
          action_url TEXT NULL,
          metadata TEXT NULL,
          image_url TEXT NULL,
          sender_id TEXT NULL,
          sender_name TEXT NULL,
          is_actionable INTEGER DEFAULT 0,
          received_at INTEGER NOT NULL,
          source TEXT DEFAULT 'fcm',
          
          CONSTRAINT chk_status CHECK (status IN ('unread', 'read', 'archived')),
          CONSTRAINT chk_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
          CONSTRAINT chk_source CHECK (source IN ('fcm', 'api'))
        )
      ''');
      
      // Create performance indexes
      await _createIndexes(txn);
    });
    
    if (kDebugMode) {
      print('Database tables created successfully');
    }
  }
  
  /// Create performance indexes
  Future<void> _createIndexes(Transaction txn) async {
    // Primary index cho status và created_at (most common query)
    await txn.execute('''
      CREATE INDEX idx_status_date ON notifications(status, created_at DESC)
    ''');
    
    // Index cho type filtering
    await txn.execute('''
      CREATE INDEX idx_type_date ON notifications(type, created_at DESC)
    ''');
    
    // Partial index cho unread notifications (high frequency query)
    await txn.execute('''
      CREATE INDEX idx_unread ON notifications(status, priority, created_at DESC) 
      WHERE status = 'unread'
    ''');
    
    // Index cho priority filtering
    await txn.execute('''
      CREATE INDEX idx_priority_date ON notifications(priority, created_at DESC)
    ''');
    
    // Index cho sender filtering
    await txn.execute('''
      CREATE INDEX idx_sender_date ON notifications(sender_id, created_at DESC)
      WHERE sender_id IS NOT NULL
    ''');
    
    // Index cho actionable notifications
    await txn.execute('''
      CREATE INDEX idx_actionable ON notifications(is_actionable, status, created_at DESC)
      WHERE is_actionable = 1
    ''');
    
    if (kDebugMode) {
      print('Database indexes created successfully');
    }
  }
  

  
  /// Handle database upgrades/migrations
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }
    
    // Future migrations will be handled here
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
  }
  
  /// Migrate to specific version
  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 2:
        // Example migration for future version
        // await db.execute('ALTER TABLE notifications ADD COLUMN new_field TEXT');
        break;
      default:
        if (kDebugMode) {
          print('No migration needed for version $version');
        }
    }
  }
  
  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      if (kDebugMode) {
        print('Database closed');
      }
    }
  }
  
  /// Delete database file (for testing/reset purposes)
  Future<void> deleteDatabase() async {
    try {
      final path = join(await getDatabasesPath(), _databaseName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
      if (kDebugMode) {
        print('Database deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting database: $e');
      }
      rethrow;
    }
  }
  
  /// Get database info for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    
    try {
      // Get table list
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      // Get notification count
      final notificationCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications'
      );
      
      // Get unread count
      final unreadCount = await db.rawQuery(
        "SELECT COUNT(*) as count FROM notifications WHERE status = 'unread'"
      );
      
      // Get database version
      final version = await db.getVersion();
      
      return {
        'version': version,
        'tables': tables.map((t) => t['name']).toList(),
        'total_notifications': notificationCount.first['count'],
        'unread_notifications': unreadCount.first['count'],
        'database_path': db.path,
        'database_name': _databaseName,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting database info: $e');
      }
      return {'error': e.toString()};
    }
  }
  
  /// Perform database maintenance (vacuum, analyze)
  Future<void> performMaintenance() async {
    final db = await database;
    
    try {
      // Vacuum database to reclaim space
      await db.execute('VACUUM');
      
      // Update table statistics
      await db.execute('ANALYZE');
      
      if (kDebugMode) {
        print('Database maintenance completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error performing database maintenance: $e');
      }
      rethrow;
    }
  }
  
  /// Check database integrity
  Future<bool> checkIntegrity() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isOk = result.isNotEmpty && result.first.values.first == 'ok';
      
      if (kDebugMode) {
        print('Database integrity check: ${isOk ? 'PASS' : 'FAIL'}');
      }
      
      return isOk;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking database integrity: $e');
      }
      return false;
    }
  }
} 