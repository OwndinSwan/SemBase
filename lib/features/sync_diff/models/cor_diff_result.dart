import '../../cor_parser/models/parsed_cor.dart';
import '../../../core/database/app_database.dart';

enum DiffType {
  added,
  modified,
  unchanged,
  dropped,
}

class CourseDiffItem {
  final String courseCode;
  final Course? existingCourse;
  final ParsedCourse? newCourse;
  final DiffType diffType;
  final List<String> changeDetails;

  CourseDiffItem({
    required this.courseCode,
    this.existingCourse,
    this.newCourse,
    required this.diffType,
    this.changeDetails = const [],
  });
}

class CorDiffSummary {
  final ParsedCorData incomingData;
  final AcademicProfile? existingProfile;
  final List<CourseDiffItem> diffItems;
  final bool isNewSemester;

  CorDiffSummary({
    required this.incomingData,
    this.existingProfile,
    required this.diffItems,
    required this.isNewSemester,
  });

  List<CourseDiffItem> get added => diffItems.where((d) => d.diffType == DiffType.added).toList();
  List<CourseDiffItem> get modified => diffItems.where((d) => d.diffType == DiffType.modified).toList();
  List<CourseDiffItem> get dropped => diffItems.where((d) => d.diffType == DiffType.dropped).toList();
  List<CourseDiffItem> get unchanged => diffItems.where((d) => d.diffType == DiffType.unchanged).toList();

  bool get hasChanges => added.isNotEmpty || modified.isNotEmpty || dropped.isNotEmpty;
}
