import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SCDateUtils {
  static String formatDateTimeString(String date, {String onError = ""}) {
    try {
      DateTime parseDate = DateTime.parse(date).toLocal();
      var outputFormat = DateFormat('dd.MM.yyyy');
      return outputFormat.format(parseDate);
    } catch (e) {
      return onError;
    }
  }

  static String formatDateTimeStringWithTime(String date,
      {String onError = ""}) {
    try {
      DateTime parseDate = DateTime.parse(date).toLocal();
      var outputFormat = DateFormat('dd.MM.yyyy - HH:mm');
      return outputFormat.format(parseDate);
    } catch (e) {
      return onError;
    }
  }

  static String formatDateTimeStringWithTimeAndSecond(String date,
      {String onError = ""}) {
    try {
      DateTime parseDate = DateTime.parse(date).toLocal();
      var outputFormat = DateFormat('dd.MM.yyyy - HH:mm:ss');
      return outputFormat.format(parseDate);
    } catch (e) {
      return onError;
    }
  }

  static String formatDateTimeStringWithOnlyTime(String date,
      {String onError = ""}) {
    try {
      DateTime parseDate = DateTime.parse(date).toLocal();
      var outputFormat = DateFormat('HH:mm');
      return outputFormat.format(parseDate);
    } catch (e) {
      return onError;
    }
  }
}

// EXTENSIONS

extension DateTimeExtension on DateTime {
  DateTime applied(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  DateTime getDateOnly() {
    return DateTime(year, month, day);
  }

  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }

  bool isTomorrow() {
    final yesterday = DateTime.now().add(const Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }
}
