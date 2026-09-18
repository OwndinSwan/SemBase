import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'time_formatter.dart';

/// Item representing a schedule entry for export
class ExportableSchedule {
  final String courseCode;
  final String courseTitle;
  final String dayToken;
  final int startMinutes;
  final int endMinutes;
  final String roomCode;
  final String sessionType;
  final String? profName;

  const ExportableSchedule({
    required this.courseCode,
    required this.courseTitle,
    required this.dayToken,
    required this.startMinutes,
    required this.endMinutes,
    required this.roomCode,
    required this.sessionType,
    this.profName,
  });
}

/// RFC 5545 standard .ics file generator and Plain Text Formatter
class IcsGenerator {
  /// Generates RFC 5545 standard .ics content
  static String generateIcsString({
    required String semesterName,
    required List<ExportableSchedule> schedules,
    DateTime? semesterStartDate,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now().toUtc();
    final nowFormatted = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
    final startDate = semesterStartDate ?? DateTime.now();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//ClassBase//SemBase 1.0//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:SemBase - $semesterName');
    buffer.writeln('X-WR-TIMEZONE:Asia/Manila');

    for (final item in schedules) {
      final uid = const Uuid().v4();
      final rfcDay = TimeFormatter.dayTokenToRfcDay(item.dayToken);
      
      // Calculate first occurrence date
      final targetWeekday = _dayTokenToWeekday(item.dayToken);
      int daysToAdd = (targetWeekday - startDate.weekday) % 7;
      if (daysToAdd < 0) daysToAdd += 7;
      final firstOccurrence = startDate.add(Duration(days: daysToAdd));

      final startHour = item.startMinutes ~/ 60;
      final startMin = item.startMinutes % 60;
      final endHour = item.endMinutes ~/ 60;
      final endMin = item.endMinutes % 60;

      final dtStart = DateTime(
        firstOccurrence.year,
        firstOccurrence.month,
        firstOccurrence.day,
        startHour,
        startMin,
      );
      final dtEnd = DateTime(
        firstOccurrence.year,
        firstOccurrence.month,
        firstOccurrence.day,
        endHour,
        endMin,
      );

      final dtStartFormatted = DateFormat("yyyyMMdd'T'HHmmss").format(dtStart);
      final dtEndFormatted = DateFormat("yyyyMMdd'T'HHmmss").format(dtEnd);

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid@sembase.classbase.org');
      buffer.writeln('DTSTAMP:$nowFormatted');
      buffer.writeln('DTSTART;TZID=Asia/Manila:$dtStartFormatted');
      buffer.writeln('DTEND;TZID=Asia/Manila:$dtEndFormatted');
      buffer.writeln('RRULE:FREQ=WEEKLY;BYDAY=$rfcDay');
      buffer.writeln('SUMMARY:${item.courseCode} - ${item.courseTitle} (${item.sessionType.toUpperCase()})');
      buffer.writeln('LOCATION:${item.roomCode}');
      buffer.writeln('DESCRIPTION:Instructor: ${item.profName ?? "TBA"}\\nSession: ${item.sessionType}\\nExported from SemBase');
      buffer.writeln('STATUS:CONFIRMED');
      buffer.writeln('TRANSP:OPAQUE');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Writes .ics file to application cache directory and returns file path
  static Future<String> exportIcsFile({
    required String semesterName,
    required List<ExportableSchedule> schedules,
    String? outputDirectoryPath,
  }) async {
    final icsContent = generateIcsString(
      semesterName: semesterName,
      schedules: schedules,
    );
    final basePath = outputDirectoryPath ?? Directory.systemTemp.path;
    final sanitizedSemester = semesterName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = '$basePath/SemBase_Schedule_$sanitizedSemester.ics';
    final file = File(filePath);
    await file.writeAsString(icsContent);
    return filePath;
  }

  /// Formats clean plain text schedule for sharing in messaging apps
  static String formatPlainTextSchedule({
    required String studentNo,
    required String section,
    required String semester,
    required List<ExportableSchedule> schedules,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📅 SemBase Academic Schedule');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (studentNo.isNotEmpty) buffer.writeln('Student No: $studentNo');
    if (section.isNotEmpty) buffer.writeln('Section: $section');
    buffer.writeln('Term: $semester');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final dayOrder = ['M', 'T', 'W', 'TH', 'F', 'S'];
    for (final day in dayOrder) {
      final dayItems = schedules.where((s) => s.dayToken.toUpperCase() == day).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

      if (dayItems.isNotEmpty) {
        buffer.writeln('📌 ${TimeFormatter.getFullDayName(day).toUpperCase()}');
        for (final item in dayItems) {
          final timeStr = TimeFormatter.formatTimeRange(item.startMinutes, item.endMinutes);
          buffer.writeln('  • $timeStr | ${item.courseCode}');
          buffer.writeln('    ${item.courseTitle}');
          buffer.writeln('    Room: ${item.roomCode} [${item.sessionType.toUpperCase()}]');
          if (item.profName != null && item.profName!.isNotEmpty) {
            buffer.writeln('    Prof: ${item.profName}');
          }
          buffer.writeln();
        }
      }
    }

    buffer.writeln('Generated with SemBase');
    return buffer.toString();
  }

  static int _dayTokenToWeekday(String dayToken) {
    switch (dayToken.toUpperCase()) {
      case 'M':
        return DateTime.monday;
      case 'T':
        return DateTime.tuesday;
      case 'W':
        return DateTime.wednesday;
      case 'TH':
        return DateTime.thursday;
      case 'F':
        return DateTime.friday;
      case 'S':
        return DateTime.saturday;
      default:
        return DateTime.monday;
    }
  }
}
