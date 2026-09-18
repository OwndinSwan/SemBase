import 'package:intl/intl.dart';

/// Utilities for academic schedule time calculations and formatting
class TimeFormatter {
  /// Converts minutes from midnight (0..1439) into 12-hour format string (e.g., "7:00 AM", "1:30 PM")
  static String formatMinutesTo12Hour(int minutes) {
    final int hours = (minutes ~/ 60) % 24;
    final int mins = minutes % 60;
    final String period = hours >= 12 ? 'PM' : 'AM';
    final int displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);
    final String displayMins = mins.toString().padLeft(2, '0');
    return '$displayHour:$displayMins $period';
  }

  /// Converts minutes from midnight into 24-hour format string (e.g., "07:00", "13:30")
  static String formatMinutesTo24Hour(int minutes) {
    final int hours = (minutes ~/ 60) % 24;
    final int mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Converts time string like "07:00", "7:00AM", "1:30PM", "13:30", "1:00", "01:00-03:00" to minutes from midnight
  static int parseTimeToMinutes(String timeStr) {
    final clean = timeStr.trim().toUpperCase();
    if (clean.isEmpty) return 0;

    // Check for AM/PM format
    final bool isPM = clean.contains('PM');
    final bool isAM = clean.contains('AM');

    // Remove letters and extra spaces
    final digitsOnly = clean.replaceAll(RegExp(r'[A-Z\s]'), '');
    final parts = digitsOnly.split(':');

    int hours = 0;
    int minutes = 0;

    if (parts.isNotEmpty) {
      hours = int.tryParse(parts[0]) ?? 0;
    }
    if (parts.length > 1) {
      minutes = int.tryParse(parts[1]) ?? 0;
    }

    if (isPM) {
      if (hours < 12) hours += 12;
    } else if (isAM) {
      if (hours == 12) hours = 0;
    } else {
      // Academic schedule heuristic when AM/PM is omitted:
      // - 1:00 to 6:59 is afternoon/evening (13:00 to 18:59)
      // - 7:00 to 11:59 is morning (07:00 to 11:59)
      // - 12:00 to 12:59 is noon (12:00 to 12:59)
      // - >= 13 is already 24-hour military format
      if (hours >= 1 && hours < 7) {
        hours += 12;
      }
    }

    return (hours * 60) + minutes;
  }

  /// Formats time range (e.g. start: 420, end: 540) -> "7:00 AM - 9:00 AM"
  static String formatTimeRange(int startMinutes, int endMinutes) {
    return '${formatMinutesTo12Hour(startMinutes)} - ${formatMinutesTo12Hour(endMinutes)}';
  }

  /// Converts DateTime weekday (1 = Monday, 7 = Sunday) to Day Token
  static String getDayTokenFromWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'TH';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      default:
        return '';
    }
  }

  /// Converts Day Token to standard RFC 5545 day code
  static String dayTokenToRfcDay(String dayToken) {
    switch (dayToken.toUpperCase()) {
      case 'M':
        return 'MO';
      case 'T':
        return 'TU';
      case 'W':
        return 'WE';
      case 'TH':
        return 'TH';
      case 'F':
        return 'FR';
      case 'S':
        return 'SA';
      default:
        return 'MO';
    }
  }

  /// Full name of day token
  static String getFullDayName(String dayToken) {
    switch (dayToken.toUpperCase()) {
      case 'M':
        return 'Monday';
      case 'T':
        return 'Tuesday';
      case 'W':
        return 'Wednesday';
      case 'TH':
        return 'Thursday';
      case 'F':
        return 'Friday';
      case 'S':
        return 'Saturday';
      case 'SU':
        return 'Sunday';
      default:
        return dayToken;
    }
  }

  /// Converts Day Token to DateTime weekday integer (1 = Monday, 7 = Sunday)
  static int dayTokenToWeekday(String dayToken) {
    switch (dayToken.toUpperCase().trim()) {
      case 'M':
      case 'MON':
        return DateTime.monday;
      case 'T':
      case 'TUE':
        return DateTime.tuesday;
      case 'W':
      case 'WED':
        return DateTime.wednesday;
      case 'TH':
      case 'THU':
        return DateTime.thursday;
      case 'F':
      case 'FRI':
        return DateTime.friday;
      case 'S':
      case 'SAT':
        return DateTime.saturday;
      case 'SU':
      case 'SUN':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  /// Formats remaining time in human readable format ("in 15m", "in 1h 20m", "45s left")
  static String formatRemainingTime(Duration duration) {
    if (duration.isNegative) return "Passed";
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    final int seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formats date for display with timezone-safe calendar day extraction
  static String formatDate(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateFormat('EEE, MMM d, yyyy').format(DateTime(local.year, local.month, local.day));
  }

  /// Normalizes any date or ISO string into a timezone-immune calendar date (noon anchor)
  static DateTime? normalizeDueDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) {
      final local = val.isUtc ? val.toLocal() : val;
      return DateTime(local.year, local.month, local.day, 12, 0, 0);
    }
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
        final parts = str.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), 12, 0, 0);
      }
      final dt = DateTime.parse(str).toLocal();
      return DateTime(dt.year, dt.month, dt.day, 12, 0, 0);
    } catch (_) {
      return null;
    }
  }
}
