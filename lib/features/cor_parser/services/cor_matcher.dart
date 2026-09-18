import '../models/parsed_cor.dart';
import '../../../core/utils/time_formatter.dart';

/// Regular expression token matcher and normalizer for Cavite State University (CvSU) COR
class CorMatcher {
  /// Normalizes and parses raw text extracted from PDF or clipboard
  static ParsedCorData parseCorText(String rawText) {
    final cleanText = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = cleanText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Header Extraction
    final studentNo = _extractStudentNumber(cleanText);
    final section = _extractSection(cleanText);
    final schoolYear = _extractSchoolYear(cleanText);
    final semester = _extractSemester(cleanText);

    // 2. Course extraction: Support both Day-Grouped Plain Text Schedules and Tabular Official CORs
    List<ParsedCourse> courses = [];
    final hasDayHeaders = RegExp(
      r'\b(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)\b',
      caseSensitive: false,
    ).hasMatch(cleanText);

    if (hasDayHeaders) {
      courses = _parseDayGroupedSchedule(lines);
    }

    if (courses.isEmpty) {
      courses = _extractCourses(cleanText, lines);
    }

    // 3. Compute total units
    double totalUnits = 0.0;
    final totalUnitsMatch = RegExp(r'(?:TOTAL\s+(?:UNITS|CREDITS|HOURS)|TOTAL|Total\s*UNITS)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false).firstMatch(cleanText);
    if (totalUnitsMatch != null) {
      totalUnits = double.tryParse(totalUnitsMatch.group(1)!) ?? 0.0;
    } else {
      for (final c in courses) {
        totalUnits += c.totalUnits;
      }
    }

    return ParsedCorData(
      studentNo: studentNo.isNotEmpty ? studentNo : '2023-00000',
      section: section.isNotEmpty ? section : 'REGULAR',
      schoolYear: schoolYear.isNotEmpty ? schoolYear : '${DateTime.now().year}-${DateTime.now().year + 1}',
      semester: semester.isNotEmpty ? semester : '1st Semester',
      totalUnits: totalUnits > 0 ? totalUnits : courses.fold(0.0, (acc, c) => acc + c.totalUnits),
      courses: courses,
    );
  }

  /// Parses day-grouped schedules e.g.:
  /// MONDAY
  /// • 7:00 AM-9:00 AM — Fundamentals in Lodging Operations (403B)
  /// • 10:00 AM-1:00 PM — Fundamentals in Lodging Operations (607B)
  static List<ParsedCourse> _parseDayGroupedSchedule(List<String> lines) {
    final Map<String, ParsedCourse> coursesByTitle = {};
    String currentDayToken = 'M';

    final dayHeaderRegex = RegExp(
      r'^\s*[*•\-_\s]*\b(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY|MON|TUE|WED|THU|FRI|SAT|SUN)\b[:\s\-_\*]*$',
      caseSensitive: false,
    );

    // Matches bullet time lines: "• 7:00 AM-9:00 AM — Fundamentals in Lodging Operations (403B)"
    final timeLineRegex = RegExp(
      r'[*•\-]?\s*([0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)?)\s*[-–—to]+\s*([0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)?)\s*[:—–\-|\t]\s*(.+)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final dayMatch = dayHeaderRegex.firstMatch(trimmed);
      if (dayMatch != null) {
        final dayStr = dayMatch.group(1)!.toUpperCase();
        if (dayStr.startsWith('MON')) currentDayToken = 'M';
        else if (dayStr.startsWith('TUE')) currentDayToken = 'T';
        else if (dayStr.startsWith('WED')) currentDayToken = 'W';
        else if (dayStr.startsWith('THU')) currentDayToken = 'TH';
        else if (dayStr.startsWith('FRI')) currentDayToken = 'F';
        else if (dayStr.startsWith('SAT')) currentDayToken = 'S';
        else if (dayStr.startsWith('SUN')) currentDayToken = 'SUN';
        continue;
      }

      final timeMatch = timeLineRegex.firstMatch(trimmed);
      if (timeMatch != null) {
        final startStr = timeMatch.group(1)!.trim();
        final endStr = timeMatch.group(2)!.trim();
        final body = timeMatch.group(3)!.trim();

        final startMinutes = TimeFormatter.parseTimeToMinutes(startStr);
        final endMinutes = TimeFormatter.parseTimeToMinutes(endStr);

        // Extract room code if inside parentheses at the end, e.g. "(403B)" or "(Kitchen Lab)"
        String courseTitle = body;
        String roomCode = 'TBA';

        final roomMatch = RegExp(r'\(([^)]+)\)\s*$').firstMatch(body);
        if (roomMatch != null) {
          roomCode = roomMatch.group(1)!.trim();
          courseTitle = body.substring(0, roomMatch.start).trim();
        }

        // Clean up course title
        courseTitle = courseTitle.replaceAll(RegExp(r'^[•\-\*—–\s]+'), '').trim();
        if (courseTitle.isEmpty) courseTitle = 'Academic Course';

        // Derive course code
        final courseCode = _deriveCourseCode(courseTitle);

        final key = courseTitle.toUpperCase();
        final schedule = ParsedSchedule(
          dayToken: currentDayToken,
          startMinutes: startMinutes,
          endMinutes: endMinutes > startMinutes ? endMinutes : startMinutes + 60,
          roomCode: roomCode.isNotEmpty ? roomCode : 'TBA',
          sessionType: roomCode.toLowerCase().contains('lab') || courseTitle.toLowerCase().contains('lab') ? 'laboratory' : 'lecture',
          isTba: roomCode.toUpperCase() == 'TBA',
        );

        if (coursesByTitle.containsKey(key)) {
          final existing = coursesByTitle[key]!;
          coursesByTitle[key] = ParsedCourse(
            courseCode: existing.courseCode,
            courseTitle: existing.courseTitle,
            lecUnits: existing.lecUnits,
            labUnits: existing.labUnits,
            schedules: [...existing.schedules, schedule],
          );
        } else {
          final isLab = schedule.sessionType == 'laboratory';
          coursesByTitle[key] = ParsedCourse(
            courseCode: courseCode,
            courseTitle: courseTitle,
            lecUnits: isLab ? 2.0 : 3.0,
            labUnits: isLab ? 1.0 : 0.0,
            schedules: [schedule],
          );
        }
      }
    }

    return coursesByTitle.values.toList();
  }

  static String _deriveCourseCode(String title) {
    // If title starts with standard code like "PE/PATHFIT 3" or "CS 101" or "ITEC 50"
    final explicitCodeMatch = RegExp(r'^([A-Za-z\/\-]+(?:\s+[0-9]+[A-Za-z]?)?)\b').firstMatch(title);
    if (explicitCodeMatch != null && RegExp(r'[0-9]').hasMatch(explicitCodeMatch.group(1)!)) {
      return explicitCodeMatch.group(1)!.toUpperCase();
    }

    // Otherwise acronym initials e.g. "Fundamentals in Lodging Operations" -> "FLO"
    final words = title.split(RegExp(r'[\s\-]+')).where((w) => w.isNotEmpty && !{'in', 'and', 'with', 'of', 'for', 'to', 'the', 'a', 'an'}.contains(w.toLowerCase())).toList();
    if (words.length >= 2) {
      return words.map((w) => w[0].toUpperCase()).join();
    }
    return title.length > 8 ? title.substring(0, 8).toUpperCase() : title.toUpperCase();
  }

  static String _extractStudentNumber(String text) {
    // Matches "Student Number: 251080168", "Student No: 2023-01928", "251080168", "2023-10492"
    final match = RegExp(r'(?:Student\s*(?:No|Number|ID)?[:\.\s]*)?([0-9]{4}-[0-9]{4,6}|[0-9]{8,12})', caseSensitive: false).firstMatch(text);
    if (match != null) return match.group(1)!;

    final fallback = RegExp(r'\b([0-9]{4}-[0-9]{4,6}|[0-9]{9})\b').firstMatch(text);
    return fallback?.group(1) ?? '';
  }

  static String _extractSection(String text) {
    const invalidPrefixes = {
      'FIRST', 'SECOND', 'THIRD', 'SUMMER', 'MIDYEAR', 'SEM', 'SEMESTER',
      'SCHOOL', 'YEAR', 'SY', 'AY', 'PAGE', 'TOTAL', 'NOTE', 'CAVITE', 'CAMPUS'
    };

    // 1. First priority: explicit "Section:" or "Yr/Sec:" label
    final sectionMatches = RegExp(
      r'(?:Section|Sec|Yr\s*\/\s*Sec|Course\s*&\s*Section)\s*[:\-]?\s*([A-Za-z]{2,8}\s*-?[0-9][0-9A-Za-z]*(?:-[0-9A-Za-z]+)?)',
      caseSensitive: false,
    ).allMatches(text);

    for (final match in sectionMatches) {
      final val = match.group(1)?.trim() ?? '';
      final upper = val.toUpperCase();
      final prefix = upper.split(RegExp(r'[\s\-]')).first;
      if (invalidPrefixes.contains(prefix) || invalidPrefixes.contains(upper)) {
        continue;
      }
      if (val.isNotEmpty) return val.replaceAll(RegExp(r'\s+'), ' ');
    }

    // 2. Second priority: degree program section pattern (e.g. BSIT-2A, BSCS 3-1, BSIT 2-4, BSEMC-1A, DIT-2A)
    final degreeSectionMatch = RegExp(
      r'\b(BS[A-Z]{2,6}\s*-?[0-9]+[A-Za-z]?(?:-[0-9]+[A-Za-z]?)?|[A-Z]{2,6}-[0-9]+[A-Za-z]?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (degreeSectionMatch != null) {
      final val = degreeSectionMatch.group(1)!.trim();
      final upper = val.toUpperCase();
      final prefix = upper.split(RegExp(r'[\s\-]')).first;
      if (!invalidPrefixes.contains(prefix) && !invalidPrefixes.contains(upper)) {
        return val.replaceAll(RegExp(r'\s+'), ' ');
      }
    }

    // 3. Fallback generic pattern
    final fallbackMatches = RegExp(r'\b([A-Z]{2,6}\s*-?[0-9]+[A-Za-z]?(?:-[0-9]+[A-Za-z]?)?)\b').allMatches(text);
    for (final m in fallbackMatches) {
      final val = m.group(1)!.trim();
      final upper = val.toUpperCase();
      final prefix = upper.split(RegExp(r'[\s\-]')).first;
      if (!invalidPrefixes.contains(prefix) && !invalidPrefixes.contains(upper)) {
        return val;
      }
    }

    return 'REGULAR';
  }

  static String _extractSchoolYear(String text) {
    // Matches "Schoolyear: 2026-2027", "2024-2025", "A.Y. 2024-2025", "SY 2024-2025"
    final match = RegExp(r'(?:A\.?Y\.?|SY|School\s*year|Schoolyear)[:\s]*([0-9]{4}\s*-\s*[0-9]{4})', caseSensitive: false).firstMatch(text);
    if (match != null) return match.group(1)!.replaceAll(' ', '');

    final general = RegExp(r'\b([0-9]{4}\s*-\s*[0-9]{4})\b').firstMatch(text);
    return general?.group(1)?.replaceAll(' ', '') ?? '';
  }

  static String _extractSemester(String text) {
    // Matches "Semester: FIRST", "1st Semester", "SECOND", "2nd Sem", "Midyear"
    if (RegExp(r'\b(?:FIRST|1st\s*(?:Sem(?:ester)?)?)\b', caseSensitive: false).hasMatch(text)) return '1st Semester';
    if (RegExp(r'\b(?:SECOND|2nd\s*(?:Sem(?:ester)?)?)\b', caseSensitive: false).hasMatch(text)) return '2nd Semester';
    if (RegExp(r'\b(?:Midyear|Summer|THIRD)\b', caseSensitive: false).hasMatch(text)) return 'Midyear';
    return '1st Semester';
  }

  static const _kForbiddenCoursePrefixes = {
    'TH', 'M', 'T', 'W', 'F', 'S', 'M/TH', 'T/F', 'W/S', 'MWF', 'TTH', 'SUN',
    'TOTAL', 'SECTION', 'PAGE', 'SY', 'AY', 'SEC', 'NOTE', 'FIRST', 'SECOND', 'THIRD',
    'UNITS', 'HOURS', 'STUDENT', 'COURSE', 'ROOM', 'DAY', 'TIME', 'SCHED', 'CODE', 'FEE', 'CCL',
    'RM', 'CL', 'ICT', 'LAB', 'HALL', 'BLDG', 'ENG', 'CC', 'CHAPTER', 'TABLE', 'FIGURE',
    'STEP', 'LEVEL', 'ITEM', 'RULE', 'TYPE', 'PRICE', 'COST', 'DATE', 'YEAR', 'TERM',
    'SEMESTER', 'GRADE', 'POINT', 'FEES', 'PAYMENT', 'RECEIPT', 'AMOUNT', 'BALANCE',
    'NAME', 'CAMPUS', 'COLLEGE', 'PROGRAM', 'TEL', 'FAX', 'EMAIL', 'REF', 'DOC', 'ID',
    'NO', 'NUM', 'OCT', 'NOV', 'DEC', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP',
    'ADDRESS', 'ENCODER', 'MAJOR', 'ASSESSMENT', 'TUITION', 'LIBRARY', 'MEDICAL', 'PUBLICATION',
    'GUIDANCE', 'SFDF', 'SRF', 'ATHLETIC', 'SCUAA', 'INTERNET', 'SCHOLARSHIP', 'TERMS',
    'REGISTRATION', 'CERTIFICATE', 'CAVITE', 'STATE', 'UNIVERSITY', 'PHILIPPINES', 'INDOS',
    'OFFICIAL', 'ENROLLED', 'ASSESSED', 'PAYABLE', 'REMARKS', 'STATUS', 'SIGNATURE'
  };

  static bool _isInvalidCourseCode(String code, String surroundingLine) {
    final u = code.toUpperCase().trim();
    final parts = u.split(RegExp(r'\s+'));
    final prefix = parts.isNotEmpty ? parts.first : u;
    if (_kForbiddenCoursePrefixes.contains(prefix) || _kForbiddenCoursePrefixes.contains(u)) {
      return true;
    }
    // Prefix must have at least 2 letters
    final letters = prefix.replaceAll(RegExp(r'[^A-Z]'), '');
    if (letters.length < 2) {
      return true;
    }
    // If code is followed by a time colon (e.g. TH 07:00)
    if (RegExp(r'\b' + RegExp.escape(code) + r'\s*:[0-9]{2}').hasMatch(surroundingLine)) {
      return true;
    }
    return false;
  }

  static List<ParsedCourse> _extractCourses(String fullText, List<String> lines) {
    final List<ParsedCourse> results = [];
    final Set<String> seenCodes = {};

    // Match course code: e.g. "GNED 04", "202610459 GNED 04", "ITEC 55A", "DCIT 24A", "FITT 3"
    final courseCodeRegex = RegExp(
      r'(?:^|[^\w])(?:[0-9]{6,10}\s+)?([A-Z]{2,6}\s+[0-9]{1,4}[A-Za-z]?)\b(?!\s*:[0-9]{2})',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip non-subject header/footer metadata
      if (RegExp(r'^(?:CAVITE|CERTIFICATE|REGISTRATION|Student|Name|Course|Address|Date|Encoder|Major|Section|Yr\/Sec|Sched\s*Code|Laboratory|Other|Assessment|Tuition|Library|Medical|Publication|Guidance|SFDF|SRF|Athletic|SCUAA|CCL|Internet|Total|Scholarship|Terms|NOTE|First|Second|Third)\b', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      if (RegExp(r'^(?:M\/TH|T\/F|W\/S|MWF|TTH|TH|M|T|W|F|S|SUN)\s+[0-9]{1,2}:[0-9]{2}', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      final match = courseCodeRegex.firstMatch(line);

      if (match != null) {
        final courseCode = match.group(1)!.trim().toUpperCase();
        if (_isInvalidCourseCode(courseCode, line)) {
          continue;
        }

        if (seenCodes.contains(courseCode)) continue;

        // Collect chunk from line i to next course code or end of section (up to 8 lines)
        final List<String> chunkLines = [line.substring(match.end).trim()];
        for (int k = i + 1; k < lines.length && k <= i + 8; k++) {
          final nextL = lines[k].trim();
          if (nextL.isEmpty) continue;
          if (courseCodeRegex.hasMatch(nextL) && !RegExp(r'^(?:M\/TH|T\/F|W\/S|MWF|TTH|TH|M|T|W|F|S|SUN)\s+[0-9]{1,2}:[0-9]{2}', caseSensitive: false).hasMatch(nextL)) {
            break;
          }
          if (RegExp(r'^(?:TOTAL|ASSESSMENT|SCHOLARSHIP|TERMS|NOTE)\b', caseSensitive: false).hasMatch(nextL)) {
            break;
          }
          chunkLines.add(nextL);
        }

        final combinedChunk = chunkLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        final course = _parseCourseRow(courseCode, combinedChunk);
        if (course != null) {
          seenCodes.add(courseCode);
          results.add(course);
        }
      }
    }

    // Global Fallback Scanner if structured line scanning didn't pick up courses
    if (results.isEmpty) {
      final globalCourseMatch = RegExp(r'\b([A-Z]{2,6}\s+[0-9]{1,4}[A-Za-z]?)\b\s+([^\n\r]+?)(?=(?:\b[A-Z]{2,6}\s+[0-9]{1,4}\b|\Z))', dotAll: true);
      for (final m in globalCourseMatch.allMatches(fullText)) {
        final code = m.group(1)!.trim().toUpperCase();
        if (_isInvalidCourseCode(code, fullText)) {
          continue;
        }
        if (seenCodes.contains(code)) continue;

        final body = m.group(2)!.trim();
        final course = _parseCourseRow(code, body);
        if (course != null) {
          seenCodes.add(code);
          results.add(course);
        }
      }
    }

    return results;
  }

  /// Parses a single CvSU subject row e.g.:
  /// "MGA BABASAHIN HINGGIL SA KASAY ... 3 10:00-12:00 / 15:00-16:00 T / F TBA / TBA"
  /// "PLATFORM TECHNOLOGIES 3 08:00-10:00 / 10:00-13:00 S / S RM.8 / CL1"
  /// "PHYSICAL ACTIVITIES TOWARDS HE ... 2 13:00-15:00 M CC"
  /// "M/TH 07:00-09:00 CL1/RM.5 LEC/LAB"
  static ParsedCourse? _parseCourseRow(String courseCode, String rest) {
    // Regex for time format in row: e.g. "10:00-12:00 / 15:00-16:00" or "13:00-15:00" or "07:00-09:00"
    final timeMatch = RegExp(r'([0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)?\s*[-–—to]\s*[0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)?(?:\s*\/\s*[0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)?\s*[-–—to]\s*[0-9]{1,2}:[0-9]{2}\s*(?:AM|PM)?)*)', caseSensitive: false).firstMatch(rest);

    if (timeMatch == null) {
      // Check if it's a TBA course with units
      final unitsMatch = RegExp(r'(?<!:)\b([0-9](?:\.0|\.5)?)(?:\s+([0-9](?:\.0|\.5)?))?(?:\s+([0-9](?:\.0|\.5)?))?\b').firstMatch(rest);
      String courseTitle = rest;
      double lecUnits = 3.0;
      double labUnits = 0.0;

      if (unitsMatch != null) {
        courseTitle = rest.substring(0, unitsMatch.start).trim();
        lecUnits = double.tryParse(unitsMatch.group(1) ?? '') ?? 3.0;
        labUnits = double.tryParse(unitsMatch.group(2) ?? '') ?? 0.0;
      }

      courseTitle = courseTitle.replaceAll(RegExp(r'\s*\.\.\.\s*$'), '').trim();
      if (courseTitle.isEmpty) courseTitle = 'Academic Course';

      return ParsedCourse(
        courseCode: courseCode,
        courseTitle: courseTitle,
        lecUnits: lecUnits,
        labUnits: labUnits,
        schedules: [
          ParsedSchedule(
            dayToken: 'M',
            startMinutes: 480,
            endMinutes: 600,
            roomCode: 'TBA',
            sessionType: labUnits > 0 ? 'lab' : 'lecture',
            isTba: true,
          ),
        ],
      );
    }

    final beforeTime = rest.substring(0, timeMatch.start).trim();
    final afterTime = rest.substring(timeMatch.end).trim();

    // 1. Extract Units and Course Title from beforeTime
    double lecUnits = 3.0;
    double labUnits = 0.0;
    String courseTitle = beforeTime;

    final unitsMatch = RegExp(r'(?<!:)\b([0-9](?:\.0|\.5)?)(?:\s+([0-9](?:\.0|\.5)?))?(?:\s+([0-9](?:\.0|\.5)?))?\b').firstMatch(beforeTime);
    if (unitsMatch != null) {
      courseTitle = beforeTime.substring(0, unitsMatch.start).trim();
      final u1 = double.tryParse(unitsMatch.group(1) ?? '') ?? 3.0;
      final u2 = double.tryParse(unitsMatch.group(2) ?? '');
      final u3 = double.tryParse(unitsMatch.group(3) ?? '');

      if (u3 != null && u2 != null) {
        lecUnits = u1;
        labUnits = u2;
      } else {
        lecUnits = u1;
        labUnits = 0.0;
      }
    }

    // Clean up course title
    courseTitle = courseTitle.replaceAll(RegExp(r'\b(M\/TH|T\/F|W\/S|M\/W|T\/TH|M\/S|S\/S|TTH|MWF|TH|M|T|W|F|S)\b', caseSensitive: false), '').trim();
    courseTitle = courseTitle.replaceAll(RegExp(r'\s*\.\.\.\s*$'), '').trim();
    if (courseTitle.isEmpty) courseTitle = 'Academic Course';

    // 2. Extract Times, Days, Rooms
    final rawTimeStr = timeMatch.group(1)!;
    final timeParts = rawTimeStr.split('/').map((t) => t.trim()).toList();

    final List<ParsedSchedule> schedules = _extractSchedulesFromTokens(timeParts, afterTime, beforeTime, labUnits > 0);

    return ParsedCourse(
      courseCode: courseCode,
      courseTitle: courseTitle,
      lecUnits: lecUnits,
      labUnits: labUnits,
      schedules: schedules,
    );
  }

  /// Pairs time slots, days, and rooms from CvSU tokens
  static List<ParsedSchedule> _extractSchedulesFromTokens(List<String> timeParts, String afterTime, String beforeTime, bool hasLab) {
    final List<ParsedSchedule> schedules = [];

    // Match day sequence in afterTime or beforeTime: e.g. "T / F", "M / W", "T / TH", "M / S", "S / S", "M/TH"
    final daySeqMatchAfter = RegExp(
      r'^(M\s*\/\s*TH|T\s*\/\s*F|W\s*\/\s*S|M\s*\/\s*W|T\s*\/\s*TH|M\s*\/\s*S|S\s*\/\s*S|T\s*\/\s*W|TTH|MWF|M\s*-\s*TH|T\s*-\s*F|W\s*-\s*S|THURSDAY|MONDAY|TUESDAY|WEDNESDAY|FRIDAY|SATURDAY|SUNDAY|THU|MON|TUE|WED|FRI|SAT|SUN|TH|M|T|W|F|S)\b',
      caseSensitive: false,
    ).firstMatch(afterTime);

    List<String> dayList = [];
    String rawRoomStr = 'TBA';

    if (daySeqMatchAfter != null) {
      final rawDaySeq = daySeqMatchAfter.group(1)!;
      dayList = _normalizeDayTokens(rawDaySeq);
      rawRoomStr = afterTime.substring(daySeqMatchAfter.end).trim();
    } else {
      // Check beforeTime for day tokens
      final daySeqMatchBefore = RegExp(
        r'\b(M\s*\/\s*TH|T\s*\/\s*F|W\s*\/\s*S|M\s*\/\s*W|T\s*\/\s*TH|M\s*\/\s*S|S\s*\/\s*S|T\s*\/\s*W|TTH|MWF|M\s*-\s*TH|T\s*-\s*F|W\s*-\s*S|THURSDAY|MONDAY|TUESDAY|WEDNESDAY|FRIDAY|SATURDAY|SUNDAY|THU|MON|TUE|WED|FRI|SAT|SUN|TH|M|T|W|F|S)\b',
        caseSensitive: false,
      ).firstMatch(beforeTime);

      if (daySeqMatchBefore != null) {
        dayList = _normalizeDayTokens(daySeqMatchBefore.group(1)!);
        rawRoomStr = afterTime.isNotEmpty ? afterTime : 'TBA';
      } else {
        dayList = ['M'];
        rawRoomStr = afterTime.isNotEmpty ? afterTime : 'TBA';
      }
    }

    // Detect and strip session type tags (LEC/LAB, LEC, LAB) from room string
    final hasLecOrLabTag = RegExp(r'\b(LEC\s*\/\s*LAB|LAB\s*\/\s*LEC|LEC|LAB|LECTURE|LABORATORY)\b', caseSensitive: false).hasMatch(rawRoomStr);
    rawRoomStr = rawRoomStr.replaceAll(RegExp(r'\b(LEC\s*\/\s*LAB|LAB\s*\/\s*LEC|LEC|LAB|LECTURE|LABORATORY)\b', caseSensitive: false), '').trim();

    final roomList = rawRoomStr.split('/').map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
    final count = timeParts.length > dayList.length ? timeParts.length : dayList.length;

    for (int i = 0; i < count; i++) {
      final timeStr = (i < timeParts.length) ? timeParts[i] : timeParts.first;
      final dayToken = (i < dayList.length) ? dayList[i] : (dayList.isNotEmpty ? dayList.last : 'M');
      final room = (i < roomList.length) ? roomList[i] : (roomList.isNotEmpty ? roomList.first : 'TBA');

      final timePartsSplit = timeStr.split(RegExp(r'\s*[-–—to]\s*', caseSensitive: false));
      int startMin = 480;
      int endMin = 600;

      if (timePartsSplit.length >= 2) {
        startMin = TimeFormatter.parseTimeToMinutes(timePartsSplit[0].trim());
        endMin = TimeFormatter.parseTimeToMinutes(timePartsSplit[1].trim());
      }

      final isLab = (i > 0 && (hasLab || hasLecOrLabTag)) || room.toUpperCase().contains('CL') || room.toUpperCase().contains('LAB');

      schedules.add(ParsedSchedule(
        dayToken: dayToken,
        startMinutes: startMin,
        endMinutes: endMin,
        roomCode: room.isEmpty ? 'TBA' : room,
        sessionType: isLab ? 'lab' : 'lecture',
        isTba: room.toUpperCase() == 'TBA' || room.isEmpty,
      ));
    }

    return schedules;
  }

  /// Normalizes composite day tokens like 'T / F', 'M / W', 'T / TH', 'S / S' into individual day tokens
  static List<String> _normalizeDayTokens(String rawDay) {
    final clean = rawDay.toUpperCase().trim();
    if (clean.contains('/') || clean.contains('-') || clean.contains(',')) {
      final parts = clean.split(RegExp(r'[\/\-,]'));
      final List<String> out = [];
      for (final p in parts) {
        final token = _standardizeDayToken(p.trim());
        if (token.isNotEmpty) out.add(token);
      }
      return out.isNotEmpty ? out : ['M'];
    }

    if (clean == 'TTH' || clean == 'T/TH' || clean == 'T-TH') {
      return ['T', 'TH'];
    }
    if (clean == 'MWF' || clean == 'M-W-F') {
      return ['M', 'W', 'F'];
    }
    if (clean == 'WS' || clean == 'W/S') {
      return ['W', 'S'];
    }
    if (clean == 'TF' || clean == 'T/F') {
      return ['T', 'F'];
    }
    if (clean == 'MTH' || clean == 'M/TH') {
      return ['M', 'TH'];
    }

    final single = _standardizeDayToken(clean);
    return single.isNotEmpty ? [single] : ['M'];
  }

  static String _standardizeDayToken(String token) {
    final u = token.toUpperCase().trim();
    if (u == 'TH' || u.startsWith('THU') || u == 'THURSDAY') return 'TH';
    if (u == 'M' || u.startsWith('MON') || u == 'MONDAY') return 'M';
    if (u == 'T' || u.startsWith('TUE') || u == 'TUESDAY') return 'T';
    if (u == 'W' || u.startsWith('WED') || u == 'WEDNESDAY') return 'W';
    if (u == 'F' || u.startsWith('FRI') || u == 'FRIDAY') return 'F';
    if (u == 'S' || u.startsWith('SAT') || u == 'SATURDAY') return 'S';
    return u;
  }
}
