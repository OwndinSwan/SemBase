import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart';
import '../config/app_config.dart';

/// Represents a single activity or diagnostic log entry
class AppLogEntry {
  final int? id;
  final DateTime timestamp;
  final String category; // 'ALARM', 'SYNC', 'AUTH', 'PERMISSION', 'ACTION', 'APP'
  final String level;    // 'INFO', 'SUCCESS', 'WARNING', 'ERROR'
  final String message;
  final String? details;
  final int createdAtMs;

  const AppLogEntry({
    this.id,
    required this.timestamp,
    required this.category,
    required this.level,
    required this.message,
    this.details,
    required this.createdAtMs,
  });

  factory AppLogEntry.fromRow(Row row) {
    return AppLogEntry(
      id: row['id'] as int?,
      timestamp: DateTime.tryParse(row['timestamp'] as String? ?? '') ?? DateTime.now(),
      category: row['category'] as String? ?? 'APP',
      level: row['level'] as String? ?? 'INFO',
      message: row['message'] as String? ?? '',
      details: row['details'] as String?,
      createdAtMs: (row['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String formatForExport() {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
    final detailStr = (details != null && details!.isNotEmpty) ? '\n       Details: $details' : '';
    return '[$timeStr] [$level] [$category] $message$detailStr';
  }
}

/// Service providing local, 100% on-device diagnostic & activity logging
/// Automatically retains only the last 30 days of logs and supports .txt export.
class AppLogService {
  static Database? _db;
  static bool _isInitialized = false;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Categories
  static const String catAlarm = 'ALARM';
  static const String catSync = 'SYNC';
  static const String catAuth = 'AUTH';
  static const String catPermission = 'PERMISSION';
  static const String catAction = 'ACTION';
  static const String catApp = 'APP';

  /// Levels
  static const String lvlInfo = 'INFO';
  static const String lvlSuccess = 'SUCCESS';
  static const String lvlWarning = 'WARNING';
  static const String lvlError = 'ERROR';

  /// Initializes the SQLite database for local logs
  static Future<void> init({Database? customDb}) async {
    if (_isInitialized && _db != null) return;

    try {
      if (customDb != null) {
        _db = customDb;
      } else if (kIsWeb) {
        _isInitialized = true;
        return;
      } else {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final dbPath = p.join(docsDir.path, 'sembase_activity_logs.db');
          _db = sqlite3.open(dbPath);
        } catch (_) {
          // Fallback to in-memory database for unit test / mock environments
          _db = sqlite3.openInMemory();
        }
      }

      // Create logs table if not exists
      _db!.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          category TEXT NOT NULL,
          level TEXT NOT NULL,
          message TEXT NOT NULL,
          details TEXT,
          created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_logs_created_at ON activity_logs (created_at);
        CREATE INDEX IF NOT EXISTS idx_logs_category ON activity_logs (category);
      ''');

      _isInitialized = true;

      // Auto-prune logs older than 30 days on startup
      await pruneOldLogs();

      info(
        catApp,
        'AppLogService initialized successfully',
        details: 'Retention: 30 days',
      );
    } catch (e, st) {
      debugPrint('AppLogService initialization error: $e\n$st');
    }
  }

  /// Automatically deletes all logs older than 30 days
  static Future<int> pruneOldLogs() async {
    if (_db == null) return 0;
    try {
      final cutoffMs = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      final stmt = _db!.prepare('DELETE FROM activity_logs WHERE created_at < ?');
      stmt.execute([cutoffMs]);
      stmt.dispose();
      final deletedCount = _db!.updatedRows;
      if (deletedCount > 0) {
        debugPrint('[AppLogService] Pruned $deletedCount log entries older than 30 days');
      }
      return deletedCount;
    } catch (e) {
      debugPrint('Error pruning old logs: $e');
      return 0;
    }
  }

  /// Internal logger implementation
  static void _writeLog({
    required String category,
    required String level,
    required String message,
    String? details,
  }) {
    final now = DateTime.now();
    final timeStr = _dateFormat.format(now);
    final nowMs = now.millisecondsSinceEpoch;

    // Always output to developer console / logcat
    debugPrint('[$timeStr] [$level] [$category] $message');
    if (details != null && details.isNotEmpty) {
      debugPrint('   Details: $details');
    }

    if (_db == null) return;

    try {
      final stmt = _db!.prepare('''
        INSERT INTO activity_logs (timestamp, category, level, message, details, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''');
      stmt.execute([timeStr, category.toUpperCase(), level.toUpperCase(), message, details, nowMs]);
      stmt.dispose();
    } catch (e) {
      debugPrint('Failed to write log to SQLite: $e');
    }
  }

  // Convenient helper log methods
  static void info(String category, String message, {String? details}) =>
      _writeLog(category: category, level: lvlInfo, message: message, details: details);

  static void success(String category, String message, {String? details}) =>
      _writeLog(category: category, level: lvlSuccess, message: message, details: details);

  static void warning(String category, String message, {String? details}) =>
      _writeLog(category: category, level: lvlWarning, message: message, details: details);

  static void error(String category, String message, {String? details}) =>
      _writeLog(category: category, level: lvlError, message: message, details: details);

  /// Queries recorded logs with optional category, level, and text search filter
  static Future<List<AppLogEntry>> getLogs({
    String? category,
    String? level,
    String? searchQuery,
    int limit = 500,
  }) async {
    if (_db == null) return [];

    try {
      final whereClauses = <String>[];
      final params = <dynamic>[];

      if (category != null && category.isNotEmpty && category.toUpperCase() != 'ALL') {
        whereClauses.add('category = ?');
        params.add(category.toUpperCase());
      }

      if (level != null && level.isNotEmpty && level.toUpperCase() != 'ALL') {
        whereClauses.add('level = ?');
        params.add(level.toUpperCase());
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClauses.add('(message LIKE ? OR details LIKE ? OR timestamp LIKE ?)');
        final queryParam = '%${searchQuery.trim()}%';
        params.add(queryParam);
        params.add(queryParam);
        params.add(queryParam);
      }

      final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
      final sql = 'SELECT * FROM activity_logs $whereSql ORDER BY created_at DESC LIMIT $limit';

      final results = _db!.select(sql, params);
      return results.map((row) => AppLogEntry.fromRow(row)).toList();
    } catch (e) {
      debugPrint('Error querying activity logs: $e');
      return [];
    }
  }

  /// Returns the total count of logs recorded in the last 30 days
  static Future<int> getLogCount() async {
    if (_db == null) return 0;
    try {
      final result = _db!.select('SELECT COUNT(*) as cnt FROM activity_logs');
      if (result.isNotEmpty) {
        return result.first['cnt'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting log count: $e');
    }
    return 0;
  }

  /// Clears all logs from local SQLite database
  static Future<void> clearAllLogs() async {
    if (_db == null) return;
    try {
      _db!.execute('DELETE FROM activity_logs');
    } catch (e) {
      debugPrint('Error clearing activity logs: $e');
    }
  }

  /// Exports all logs to a clean formatted .txt file and triggers the Android share sheet
  static Future<String> exportLogsAsText() async {
    final logs = await getLogs(limit: 2000);
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final formattedExportDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final buffer = StringBuffer();
    buffer.writeln('=======================================================');
    buffer.writeln('  ${AppConfig.appName.toUpperCase()} ACTIVITY & DIAGNOSTIC LOGS');
    buffer.writeln('  Exported: $formattedExportDate');
    buffer.writeln('  Total Log Entries: ${logs.length}');
    buffer.writeln('  Retention Policy: 30 Days (Local Device Storage)');
    buffer.writeln('=======================================================');
    buffer.writeln('');

    if (logs.isEmpty) {
      buffer.writeln('No activity logs recorded yet.');
    } else {
      for (final log in logs) {
        buffer.writeln(log.formatForExport());
      }
    }

    buffer.writeln('');
    buffer.writeln('=======================================================');
    buffer.writeln('  END OF LOG EXPORT');
    buffer.writeln('=======================================================');

    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'sembase_activity_logs_$dateStr.txt'));
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      text: 'SemBase Activity & Diagnostic Logs ($formattedExportDate)',
      subject: 'SemBase Activity Logs',
    );

    success(
      catApp,
      'Activity logs exported to text file',
      details: 'File: ${file.path}, Total entries: ${logs.length}',
    );

    return file.path;
  }
}
