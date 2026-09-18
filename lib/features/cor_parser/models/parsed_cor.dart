/// Representation of a schedule slot parsed from COR
class ParsedSchedule {
  final String dayToken; // 'M'|'T'|'W'|'TH'|'F'|'S'
  final int startMinutes; // Minutes from midnight
  final int endMinutes;
  final String roomCode;
  final String sessionType; // 'lecture' | 'lab'
  final bool isTba;

  const ParsedSchedule({
    required this.dayToken,
    required this.startMinutes,
    required this.endMinutes,
    required this.roomCode,
    required this.sessionType,
    this.isTba = false,
  });

  Map<String, dynamic> toJson() => {
    'dayToken': dayToken,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'roomCode': roomCode,
    'sessionType': sessionType,
    'isTba': isTba,
  };
}

/// Representation of a single course parsed from COR
class ParsedCourse {
  final String courseCode;
  final String courseTitle;
  final double lecUnits;
  final double labUnits;
  final String? instructorName;
  final List<ParsedSchedule> schedules;

  const ParsedCourse({
    required this.courseCode,
    required this.courseTitle,
    required this.lecUnits,
    required this.labUnits,
    this.instructorName,
    required this.schedules,
  });

  double get totalUnits => lecUnits + labUnits;

  Map<String, dynamic> toJson() => {
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'lecUnits': lecUnits,
    'labUnits': labUnits,
    if (instructorName != null) 'instructorName': instructorName,
    'schedules': schedules.map((s) => s.toJson()).toList(),
  };
}

/// Representation of the full Certificate of Registration (COR) parsed data
class ParsedCorData {
  final String studentNo;
  final String section;
  final String schoolYear;
  final String semester;
  final double totalUnits;
  final List<ParsedCourse> courses;

  const ParsedCorData({
    required this.studentNo,
    required this.section,
    required this.schoolYear,
    required this.semester,
    required this.totalUnits,
    required this.courses,
  });

  factory ParsedCorData.empty() => const ParsedCorData(
    studentNo: '',
    section: '',
    schoolYear: '',
    semester: '',
    totalUnits: 0.0,
    courses: [],
  );

  Map<String, dynamic> toJson() => {
    'studentNo': studentNo,
    'section': section,
    'schoolYear': schoolYear,
    'semester': semester,
    'totalUnits': totalUnits,
    'courses': courses.map((c) => c.toJson()).toList(),
  };
}
