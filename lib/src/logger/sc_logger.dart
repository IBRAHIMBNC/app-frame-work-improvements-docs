import 'dart:io';

import 'package:csv/csv.dart';
import 'package:sc_appframework/src/storage/sc_internal_storage.dart';
import 'package:sc_appframework/src/utils/sc_file_utils.dart';

class SCLogger {
  static LogLevel logLevel = LogLevel.ERROR;

  static late File _logFile;
  static File get logFile => _logFile;

  static late List<List<dynamic>> _rows = [];
  static Future<void> initLog() async {
    _logFile = await SCInternalStorage.getFile(
      '',
      'logs.csv',
    );

    if (!_logFile.existsSync()) {
      _logFile = await SCFileUtils.createFile("logs.csv");
    }

    String csvLogString = _logFile.readAsStringSync();
    _rows = const CsvToListConverter().convert(csvLogString);
  }

  static void d(String message) async {
    _log(LogLevel.DEBUG, message);
  }

  static Future<void> i(String message) async {
    _log(LogLevel.INFO, message);
  }

  static Future<void> w(String message) async {
    _log(LogLevel.WARNING, message);
  }

  static Future<void> e(String message) async {
    _log(LogLevel.ERROR, message);
  }

  static Future<void> f(String message) async {
    _log(LogLevel.FATAL, message);
  }

  static void _log(LogLevel logLevel, String message) {
    // only log Logs when loglevel is correctly set
    if (logIdMap[logLevel]! < logIdMap[SCLogger.logLevel]!) {
      return;
    }
    _rows.add(
      [
        DateTime.now().toIso8601String(),
        message,
        logIdMap[logLevel],
      ],
    );

    _logFile.writeAsStringSync(const ListToCsvConverter().convert(_rows));
  }

  static List<List<dynamic>> get rows {
    return _rows;
  }

  static Map<LogLevel, int> logIdMap = {
    LogLevel.DEBUG: 1,
    LogLevel.INFO: 2,
    LogLevel.WARNING: 3,
    LogLevel.ERROR: 4,
    LogLevel.FATAL: 5,
  };

  static Map<int, LogLevel> get idLogMap {
    var reversed = SCLogger.logIdMap.map((k, v) => MapEntry(v, k));
    return reversed;
  }

  static Future<void> deleteLogs() async {
    _rows.clear();
    await _logFile.writeAsString(
      const ListToCsvConverter().convert(_rows),
      flush: true,
    );
  }
}

enum LogLevel {
  DEBUG,
  INFO,
  WARNING,
  ERROR,
  FATAL,
}
