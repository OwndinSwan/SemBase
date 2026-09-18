// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AcademicProfilesTable extends AcademicProfiles
    with TableInfo<$AcademicProfilesTable, AcademicProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcademicProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentNoMeta = const VerificationMeta(
    'studentNo',
  );
  @override
  late final GeneratedColumn<String> studentNo = GeneratedColumn<String>(
    'student_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolYearMeta = const VerificationMeta(
    'schoolYear',
  );
  @override
  late final GeneratedColumn<String> schoolYear = GeneratedColumn<String>(
    'school_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalUnitsMeta = const VerificationMeta(
    'totalUnits',
  );
  @override
  late final GeneratedColumn<double> totalUnits = GeneratedColumn<double>(
    'total_units',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentNo,
    section,
    schoolYear,
    semester,
    totalUnits,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'academic_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcademicProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('student_no')) {
      context.handle(
        _studentNoMeta,
        studentNo.isAcceptableOrUnknown(data['student_no']!, _studentNoMeta),
      );
    } else if (isInserting) {
      context.missing(_studentNoMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('school_year')) {
      context.handle(
        _schoolYearMeta,
        schoolYear.isAcceptableOrUnknown(data['school_year']!, _schoolYearMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolYearMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('total_units')) {
      context.handle(
        _totalUnitsMeta,
        totalUnits.isAcceptableOrUnknown(data['total_units']!, _totalUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalUnitsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AcademicProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcademicProfile(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      studentNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}student_no'],
          )!,
      section:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}section'],
          )!,
      schoolYear:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}school_year'],
          )!,
      semester:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}semester'],
          )!,
      totalUnits:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_units'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $AcademicProfilesTable createAlias(String alias) {
    return $AcademicProfilesTable(attachedDatabase, alias);
  }
}

class AcademicProfile extends DataClass implements Insertable<AcademicProfile> {
  final String id;
  final String studentNo;
  final String section;
  final String schoolYear;
  final String semester;
  final double totalUnits;
  final DateTime updatedAt;
  const AcademicProfile({
    required this.id,
    required this.studentNo,
    required this.section,
    required this.schoolYear,
    required this.semester,
    required this.totalUnits,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['student_no'] = Variable<String>(studentNo);
    map['section'] = Variable<String>(section);
    map['school_year'] = Variable<String>(schoolYear);
    map['semester'] = Variable<String>(semester);
    map['total_units'] = Variable<double>(totalUnits);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AcademicProfilesCompanion toCompanion(bool nullToAbsent) {
    return AcademicProfilesCompanion(
      id: Value(id),
      studentNo: Value(studentNo),
      section: Value(section),
      schoolYear: Value(schoolYear),
      semester: Value(semester),
      totalUnits: Value(totalUnits),
      updatedAt: Value(updatedAt),
    );
  }

  factory AcademicProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcademicProfile(
      id: serializer.fromJson<String>(json['id']),
      studentNo: serializer.fromJson<String>(json['studentNo']),
      section: serializer.fromJson<String>(json['section']),
      schoolYear: serializer.fromJson<String>(json['schoolYear']),
      semester: serializer.fromJson<String>(json['semester']),
      totalUnits: serializer.fromJson<double>(json['totalUnits']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'studentNo': serializer.toJson<String>(studentNo),
      'section': serializer.toJson<String>(section),
      'schoolYear': serializer.toJson<String>(schoolYear),
      'semester': serializer.toJson<String>(semester),
      'totalUnits': serializer.toJson<double>(totalUnits),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AcademicProfile copyWith({
    String? id,
    String? studentNo,
    String? section,
    String? schoolYear,
    String? semester,
    double? totalUnits,
    DateTime? updatedAt,
  }) => AcademicProfile(
    id: id ?? this.id,
    studentNo: studentNo ?? this.studentNo,
    section: section ?? this.section,
    schoolYear: schoolYear ?? this.schoolYear,
    semester: semester ?? this.semester,
    totalUnits: totalUnits ?? this.totalUnits,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AcademicProfile copyWithCompanion(AcademicProfilesCompanion data) {
    return AcademicProfile(
      id: data.id.present ? data.id.value : this.id,
      studentNo: data.studentNo.present ? data.studentNo.value : this.studentNo,
      section: data.section.present ? data.section.value : this.section,
      schoolYear:
          data.schoolYear.present ? data.schoolYear.value : this.schoolYear,
      semester: data.semester.present ? data.semester.value : this.semester,
      totalUnits:
          data.totalUnits.present ? data.totalUnits.value : this.totalUnits,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcademicProfile(')
          ..write('id: $id, ')
          ..write('studentNo: $studentNo, ')
          ..write('section: $section, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('semester: $semester, ')
          ..write('totalUnits: $totalUnits, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentNo,
    section,
    schoolYear,
    semester,
    totalUnits,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcademicProfile &&
          other.id == this.id &&
          other.studentNo == this.studentNo &&
          other.section == this.section &&
          other.schoolYear == this.schoolYear &&
          other.semester == this.semester &&
          other.totalUnits == this.totalUnits &&
          other.updatedAt == this.updatedAt);
}

class AcademicProfilesCompanion extends UpdateCompanion<AcademicProfile> {
  final Value<String> id;
  final Value<String> studentNo;
  final Value<String> section;
  final Value<String> schoolYear;
  final Value<String> semester;
  final Value<double> totalUnits;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AcademicProfilesCompanion({
    this.id = const Value.absent(),
    this.studentNo = const Value.absent(),
    this.section = const Value.absent(),
    this.schoolYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.totalUnits = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AcademicProfilesCompanion.insert({
    required String id,
    required String studentNo,
    required String section,
    required String schoolYear,
    required String semester,
    required double totalUnits,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       studentNo = Value(studentNo),
       section = Value(section),
       schoolYear = Value(schoolYear),
       semester = Value(semester),
       totalUnits = Value(totalUnits);
  static Insertable<AcademicProfile> custom({
    Expression<String>? id,
    Expression<String>? studentNo,
    Expression<String>? section,
    Expression<String>? schoolYear,
    Expression<String>? semester,
    Expression<double>? totalUnits,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentNo != null) 'student_no': studentNo,
      if (section != null) 'section': section,
      if (schoolYear != null) 'school_year': schoolYear,
      if (semester != null) 'semester': semester,
      if (totalUnits != null) 'total_units': totalUnits,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AcademicProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? studentNo,
    Value<String>? section,
    Value<String>? schoolYear,
    Value<String>? semester,
    Value<double>? totalUnits,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AcademicProfilesCompanion(
      id: id ?? this.id,
      studentNo: studentNo ?? this.studentNo,
      section: section ?? this.section,
      schoolYear: schoolYear ?? this.schoolYear,
      semester: semester ?? this.semester,
      totalUnits: totalUnits ?? this.totalUnits,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (studentNo.present) {
      map['student_no'] = Variable<String>(studentNo.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (schoolYear.present) {
      map['school_year'] = Variable<String>(schoolYear.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (totalUnits.present) {
      map['total_units'] = Variable<double>(totalUnits.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcademicProfilesCompanion(')
          ..write('id: $id, ')
          ..write('studentNo: $studentNo, ')
          ..write('section: $section, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('semester: $semester, ')
          ..write('totalUnits: $totalUnits, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _courseCodeMeta = const VerificationMeta(
    'courseCode',
  );
  @override
  late final GeneratedColumn<String> courseCode = GeneratedColumn<String>(
    'course_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseTitleMeta = const VerificationMeta(
    'courseTitle',
  );
  @override
  late final GeneratedColumn<String> courseTitle = GeneratedColumn<String>(
    'course_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecUnitsMeta = const VerificationMeta(
    'lecUnits',
  );
  @override
  late final GeneratedColumn<double> lecUnits = GeneratedColumn<double>(
    'lec_units',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _labUnitsMeta = const VerificationMeta(
    'labUnits',
  );
  @override
  late final GeneratedColumn<double> labUnits = GeneratedColumn<double>(
    'lab_units',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    courseCode,
    courseTitle,
    lecUnits,
    labUnits,
    isArchived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('course_code')) {
      context.handle(
        _courseCodeMeta,
        courseCode.isAcceptableOrUnknown(data['course_code']!, _courseCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_courseCodeMeta);
    }
    if (data.containsKey('course_title')) {
      context.handle(
        _courseTitleMeta,
        courseTitle.isAcceptableOrUnknown(
          data['course_title']!,
          _courseTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseTitleMeta);
    }
    if (data.containsKey('lec_units')) {
      context.handle(
        _lecUnitsMeta,
        lecUnits.isAcceptableOrUnknown(data['lec_units']!, _lecUnitsMeta),
      );
    }
    if (data.containsKey('lab_units')) {
      context.handle(
        _labUnitsMeta,
        labUnits.isAcceptableOrUnknown(data['lab_units']!, _labUnitsMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      profileId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}profile_id'],
          )!,
      courseCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}course_code'],
          )!,
      courseTitle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}course_title'],
          )!,
      lecUnits:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}lec_units'],
          )!,
      labUnits:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}lab_units'],
          )!,
      isArchived:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_archived'],
          )!,
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class Course extends DataClass implements Insertable<Course> {
  final String id;
  final String profileId;
  final String courseCode;
  final String courseTitle;
  final double lecUnits;
  final double labUnits;
  final bool isArchived;
  const Course({
    required this.id,
    required this.profileId,
    required this.courseCode,
    required this.courseTitle,
    required this.lecUnits,
    required this.labUnits,
    required this.isArchived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['course_code'] = Variable<String>(courseCode);
    map['course_title'] = Variable<String>(courseTitle);
    map['lec_units'] = Variable<double>(lecUnits);
    map['lab_units'] = Variable<double>(labUnits);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      courseCode: Value(courseCode),
      courseTitle: Value(courseTitle),
      lecUnits: Value(lecUnits),
      labUnits: Value(labUnits),
      isArchived: Value(isArchived),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      courseCode: serializer.fromJson<String>(json['courseCode']),
      courseTitle: serializer.fromJson<String>(json['courseTitle']),
      lecUnits: serializer.fromJson<double>(json['lecUnits']),
      labUnits: serializer.fromJson<double>(json['labUnits']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'courseCode': serializer.toJson<String>(courseCode),
      'courseTitle': serializer.toJson<String>(courseTitle),
      'lecUnits': serializer.toJson<double>(lecUnits),
      'labUnits': serializer.toJson<double>(labUnits),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  Course copyWith({
    String? id,
    String? profileId,
    String? courseCode,
    String? courseTitle,
    double? lecUnits,
    double? labUnits,
    bool? isArchived,
  }) => Course(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    courseCode: courseCode ?? this.courseCode,
    courseTitle: courseTitle ?? this.courseTitle,
    lecUnits: lecUnits ?? this.lecUnits,
    labUnits: labUnits ?? this.labUnits,
    isArchived: isArchived ?? this.isArchived,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      courseCode:
          data.courseCode.present ? data.courseCode.value : this.courseCode,
      courseTitle:
          data.courseTitle.present ? data.courseTitle.value : this.courseTitle,
      lecUnits: data.lecUnits.present ? data.lecUnits.value : this.lecUnits,
      labUnits: data.labUnits.present ? data.labUnits.value : this.labUnits,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseTitle: $courseTitle, ')
          ..write('lecUnits: $lecUnits, ')
          ..write('labUnits: $labUnits, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    courseCode,
    courseTitle,
    lecUnits,
    labUnits,
    isArchived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.courseCode == this.courseCode &&
          other.courseTitle == this.courseTitle &&
          other.lecUnits == this.lecUnits &&
          other.labUnits == this.labUnits &&
          other.isArchived == this.isArchived);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> courseCode;
  final Value<String> courseTitle;
  final Value<double> lecUnits;
  final Value<double> labUnits;
  final Value<bool> isArchived;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.courseCode = const Value.absent(),
    this.courseTitle = const Value.absent(),
    this.lecUnits = const Value.absent(),
    this.labUnits = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String profileId,
    required String courseCode,
    required String courseTitle,
    this.lecUnits = const Value.absent(),
    this.labUnits = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       courseCode = Value(courseCode),
       courseTitle = Value(courseTitle);
  static Insertable<Course> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? courseCode,
    Expression<String>? courseTitle,
    Expression<double>? lecUnits,
    Expression<double>? labUnits,
    Expression<bool>? isArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (courseCode != null) 'course_code': courseCode,
      if (courseTitle != null) 'course_title': courseTitle,
      if (lecUnits != null) 'lec_units': lecUnits,
      if (labUnits != null) 'lab_units': labUnits,
      if (isArchived != null) 'is_archived': isArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? courseCode,
    Value<String>? courseTitle,
    Value<double>? lecUnits,
    Value<double>? labUnits,
    Value<bool>? isArchived,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      lecUnits: lecUnits ?? this.lecUnits,
      labUnits: labUnits ?? this.labUnits,
      isArchived: isArchived ?? this.isArchived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (courseCode.present) {
      map['course_code'] = Variable<String>(courseCode.value);
    }
    if (courseTitle.present) {
      map['course_title'] = Variable<String>(courseTitle.value);
    }
    if (lecUnits.present) {
      map['lec_units'] = Variable<double>(lecUnits.value);
    }
    if (labUnits.present) {
      map['lab_units'] = Variable<double>(labUnits.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseTitle: $courseTitle, ')
          ..write('lecUnits: $lecUnits, ')
          ..write('labUnits: $labUnits, ')
          ..write('isArchived: $isArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseSchedulesTable extends CourseSchedules
    with TableInfo<$CourseSchedulesTable, CourseSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayTokenMeta = const VerificationMeta(
    'dayToken',
  );
  @override
  late final GeneratedColumn<String> dayToken = GeneratedColumn<String>(
    'day_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinutesMeta = const VerificationMeta(
    'endMinutes',
  );
  @override
  late final GeneratedColumn<int> endMinutes = GeneratedColumn<int>(
    'end_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomCodeMeta = const VerificationMeta(
    'roomCode',
  );
  @override
  late final GeneratedColumn<String> roomCode = GeneratedColumn<String>(
    'room_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTbaMeta = const VerificationMeta('isTba');
  @override
  late final GeneratedColumn<bool> isTba = GeneratedColumn<bool>(
    'is_tba',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tba" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    dayToken,
    startMinutes,
    endMinutes,
    roomCode,
    sessionType,
    isTba,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('day_token')) {
      context.handle(
        _dayTokenMeta,
        dayToken.isAcceptableOrUnknown(data['day_token']!, _dayTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_dayTokenMeta);
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinutesMeta);
    }
    if (data.containsKey('end_minutes')) {
      context.handle(
        _endMinutesMeta,
        endMinutes.isAcceptableOrUnknown(data['end_minutes']!, _endMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinutesMeta);
    }
    if (data.containsKey('room_code')) {
      context.handle(
        _roomCodeMeta,
        roomCode.isAcceptableOrUnknown(data['room_code']!, _roomCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roomCodeMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('is_tba')) {
      context.handle(
        _isTbaMeta,
        isTba.isAcceptableOrUnknown(data['is_tba']!, _isTbaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseSchedule(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      courseId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}course_id'],
          )!,
      dayToken:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}day_token'],
          )!,
      startMinutes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}start_minutes'],
          )!,
      endMinutes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}end_minutes'],
          )!,
      roomCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}room_code'],
          )!,
      sessionType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}session_type'],
          )!,
      isTba:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_tba'],
          )!,
    );
  }

  @override
  $CourseSchedulesTable createAlias(String alias) {
    return $CourseSchedulesTable(attachedDatabase, alias);
  }
}

class CourseSchedule extends DataClass implements Insertable<CourseSchedule> {
  final String id;
  final String courseId;
  final String dayToken;
  final int startMinutes;
  final int endMinutes;
  final String roomCode;
  final String sessionType;
  final bool isTba;
  const CourseSchedule({
    required this.id,
    required this.courseId,
    required this.dayToken,
    required this.startMinutes,
    required this.endMinutes,
    required this.roomCode,
    required this.sessionType,
    required this.isTba,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['day_token'] = Variable<String>(dayToken);
    map['start_minutes'] = Variable<int>(startMinutes);
    map['end_minutes'] = Variable<int>(endMinutes);
    map['room_code'] = Variable<String>(roomCode);
    map['session_type'] = Variable<String>(sessionType);
    map['is_tba'] = Variable<bool>(isTba);
    return map;
  }

  CourseSchedulesCompanion toCompanion(bool nullToAbsent) {
    return CourseSchedulesCompanion(
      id: Value(id),
      courseId: Value(courseId),
      dayToken: Value(dayToken),
      startMinutes: Value(startMinutes),
      endMinutes: Value(endMinutes),
      roomCode: Value(roomCode),
      sessionType: Value(sessionType),
      isTba: Value(isTba),
    );
  }

  factory CourseSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseSchedule(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      dayToken: serializer.fromJson<String>(json['dayToken']),
      startMinutes: serializer.fromJson<int>(json['startMinutes']),
      endMinutes: serializer.fromJson<int>(json['endMinutes']),
      roomCode: serializer.fromJson<String>(json['roomCode']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      isTba: serializer.fromJson<bool>(json['isTba']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'dayToken': serializer.toJson<String>(dayToken),
      'startMinutes': serializer.toJson<int>(startMinutes),
      'endMinutes': serializer.toJson<int>(endMinutes),
      'roomCode': serializer.toJson<String>(roomCode),
      'sessionType': serializer.toJson<String>(sessionType),
      'isTba': serializer.toJson<bool>(isTba),
    };
  }

  CourseSchedule copyWith({
    String? id,
    String? courseId,
    String? dayToken,
    int? startMinutes,
    int? endMinutes,
    String? roomCode,
    String? sessionType,
    bool? isTba,
  }) => CourseSchedule(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    dayToken: dayToken ?? this.dayToken,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    roomCode: roomCode ?? this.roomCode,
    sessionType: sessionType ?? this.sessionType,
    isTba: isTba ?? this.isTba,
  );
  CourseSchedule copyWithCompanion(CourseSchedulesCompanion data) {
    return CourseSchedule(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      dayToken: data.dayToken.present ? data.dayToken.value : this.dayToken,
      startMinutes:
          data.startMinutes.present
              ? data.startMinutes.value
              : this.startMinutes,
      endMinutes:
          data.endMinutes.present ? data.endMinutes.value : this.endMinutes,
      roomCode: data.roomCode.present ? data.roomCode.value : this.roomCode,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      isTba: data.isTba.present ? data.isTba.value : this.isTba,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseSchedule(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('dayToken: $dayToken, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('roomCode: $roomCode, ')
          ..write('sessionType: $sessionType, ')
          ..write('isTba: $isTba')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    dayToken,
    startMinutes,
    endMinutes,
    roomCode,
    sessionType,
    isTba,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseSchedule &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.dayToken == this.dayToken &&
          other.startMinutes == this.startMinutes &&
          other.endMinutes == this.endMinutes &&
          other.roomCode == this.roomCode &&
          other.sessionType == this.sessionType &&
          other.isTba == this.isTba);
}

class CourseSchedulesCompanion extends UpdateCompanion<CourseSchedule> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> dayToken;
  final Value<int> startMinutes;
  final Value<int> endMinutes;
  final Value<String> roomCode;
  final Value<String> sessionType;
  final Value<bool> isTba;
  final Value<int> rowid;
  const CourseSchedulesCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.dayToken = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.endMinutes = const Value.absent(),
    this.roomCode = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.isTba = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseSchedulesCompanion.insert({
    required String id,
    required String courseId,
    required String dayToken,
    required int startMinutes,
    required int endMinutes,
    required String roomCode,
    required String sessionType,
    this.isTba = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       dayToken = Value(dayToken),
       startMinutes = Value(startMinutes),
       endMinutes = Value(endMinutes),
       roomCode = Value(roomCode),
       sessionType = Value(sessionType);
  static Insertable<CourseSchedule> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? dayToken,
    Expression<int>? startMinutes,
    Expression<int>? endMinutes,
    Expression<String>? roomCode,
    Expression<String>? sessionType,
    Expression<bool>? isTba,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (dayToken != null) 'day_token': dayToken,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (endMinutes != null) 'end_minutes': endMinutes,
      if (roomCode != null) 'room_code': roomCode,
      if (sessionType != null) 'session_type': sessionType,
      if (isTba != null) 'is_tba': isTba,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? dayToken,
    Value<int>? startMinutes,
    Value<int>? endMinutes,
    Value<String>? roomCode,
    Value<String>? sessionType,
    Value<bool>? isTba,
    Value<int>? rowid,
  }) {
    return CourseSchedulesCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      dayToken: dayToken ?? this.dayToken,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      roomCode: roomCode ?? this.roomCode,
      sessionType: sessionType ?? this.sessionType,
      isTba: isTba ?? this.isTba,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (dayToken.present) {
      map['day_token'] = Variable<String>(dayToken.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (endMinutes.present) {
      map['end_minutes'] = Variable<int>(endMinutes.value);
    }
    if (roomCode.present) {
      map['room_code'] = Variable<String>(roomCode.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (isTba.present) {
      map['is_tba'] = Variable<bool>(isTba.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('dayToken: $dayToken, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('endMinutes: $endMinutes, ')
          ..write('roomCode: $roomCode, ')
          ..write('sessionType: $sessionType, ')
          ..write('isTba: $isTba, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseTasksTable extends CourseTasks
    with TableInfo<$CourseTasksTable, CourseTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskTypeMeta = const VerificationMeta(
    'taskType',
  );
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
    'task_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    title,
    details,
    taskType,
    isCompleted,
    dueDate,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('task_type')) {
      context.handle(
        _taskTypeMeta,
        taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseTask(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      courseId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}course_id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      taskType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}task_type'],
          )!,
      isCompleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_completed'],
          )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CourseTasksTable createAlias(String alias) {
    return $CourseTasksTable(attachedDatabase, alias);
  }
}

class CourseTask extends DataClass implements Insertable<CourseTask> {
  final String id;
  final String courseId;
  final String title;
  final String? details;
  final String taskType;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime updatedAt;
  const CourseTask({
    required this.id,
    required this.courseId,
    required this.title,
    this.details,
    required this.taskType,
    required this.isCompleted,
    this.dueDate,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    map['task_type'] = Variable<String>(taskType);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CourseTasksCompanion toCompanion(bool nullToAbsent) {
    return CourseTasksCompanion(
      id: Value(id),
      courseId: Value(courseId),
      title: Value(title),
      details:
          details == null && nullToAbsent
              ? const Value.absent()
              : Value(details),
      taskType: Value(taskType),
      isCompleted: Value(isCompleted),
      dueDate:
          dueDate == null && nullToAbsent
              ? const Value.absent()
              : Value(dueDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory CourseTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseTask(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      title: serializer.fromJson<String>(json['title']),
      details: serializer.fromJson<String?>(json['details']),
      taskType: serializer.fromJson<String>(json['taskType']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'title': serializer.toJson<String>(title),
      'details': serializer.toJson<String?>(details),
      'taskType': serializer.toJson<String>(taskType),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CourseTask copyWith({
    String? id,
    String? courseId,
    String? title,
    Value<String?> details = const Value.absent(),
    String? taskType,
    bool? isCompleted,
    Value<DateTime?> dueDate = const Value.absent(),
    DateTime? updatedAt,
  }) => CourseTask(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    title: title ?? this.title,
    details: details.present ? details.value : this.details,
    taskType: taskType ?? this.taskType,
    isCompleted: isCompleted ?? this.isCompleted,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CourseTask copyWithCompanion(CourseTasksCompanion data) {
    return CourseTask(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      title: data.title.present ? data.title.value : this.title,
      details: data.details.present ? data.details.value : this.details,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseTask(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('details: $details, ')
          ..write('taskType: $taskType, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dueDate: $dueDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    title,
    details,
    taskType,
    isCompleted,
    dueDate,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseTask &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.title == this.title &&
          other.details == this.details &&
          other.taskType == this.taskType &&
          other.isCompleted == this.isCompleted &&
          other.dueDate == this.dueDate &&
          other.updatedAt == this.updatedAt);
}

class CourseTasksCompanion extends UpdateCompanion<CourseTask> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> title;
  final Value<String?> details;
  final Value<String> taskType;
  final Value<bool> isCompleted;
  final Value<DateTime?> dueDate;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CourseTasksCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.title = const Value.absent(),
    this.details = const Value.absent(),
    this.taskType = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseTasksCompanion.insert({
    required String id,
    required String courseId,
    required String title,
    this.details = const Value.absent(),
    required String taskType,
    this.isCompleted = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       title = Value(title),
       taskType = Value(taskType);
  static Insertable<CourseTask> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? title,
    Expression<String>? details,
    Expression<String>? taskType,
    Expression<bool>? isCompleted,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (title != null) 'title': title,
      if (details != null) 'details': details,
      if (taskType != null) 'task_type': taskType,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (dueDate != null) 'due_date': dueDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? title,
    Value<String?>? details,
    Value<String>? taskType,
    Value<bool>? isCompleted,
    Value<DateTime?>? dueDate,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CourseTasksCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      details: details ?? this.details,
      taskType: taskType ?? this.taskType,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseTasksCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('details: $details, ')
          ..write('taskType: $taskType, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dueDate: $dueDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseMetadataTable extends CourseMetadata
    with TableInfo<$CourseMetadataTable, CourseMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _classroomUrlMeta = const VerificationMeta(
    'classroomUrl',
  );
  @override
  late final GeneratedColumn<String> classroomUrl = GeneratedColumn<String>(
    'classroom_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lmsUrlMeta = const VerificationMeta('lmsUrl');
  @override
  late final GeneratedColumn<String> lmsUrl = GeneratedColumn<String>(
    'lms_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profNameMeta = const VerificationMeta(
    'profName',
  );
  @override
  late final GeneratedColumn<String> profName = GeneratedColumn<String>(
    'prof_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profEmailMeta = const VerificationMeta(
    'profEmail',
  );
  @override
  late final GeneratedColumn<String> profEmail = GeneratedColumn<String>(
    'prof_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consultationHoursMeta = const VerificationMeta(
    'consultationHours',
  );
  @override
  late final GeneratedColumn<String> consultationHours =
      GeneratedColumn<String>(
        'consultation_hours',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    classroomUrl,
    lmsUrl,
    profName,
    profEmail,
    consultationHours,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('classroom_url')) {
      context.handle(
        _classroomUrlMeta,
        classroomUrl.isAcceptableOrUnknown(
          data['classroom_url']!,
          _classroomUrlMeta,
        ),
      );
    }
    if (data.containsKey('lms_url')) {
      context.handle(
        _lmsUrlMeta,
        lmsUrl.isAcceptableOrUnknown(data['lms_url']!, _lmsUrlMeta),
      );
    }
    if (data.containsKey('prof_name')) {
      context.handle(
        _profNameMeta,
        profName.isAcceptableOrUnknown(data['prof_name']!, _profNameMeta),
      );
    }
    if (data.containsKey('prof_email')) {
      context.handle(
        _profEmailMeta,
        profEmail.isAcceptableOrUnknown(data['prof_email']!, _profEmailMeta),
      );
    }
    if (data.containsKey('consultation_hours')) {
      context.handle(
        _consultationHoursMeta,
        consultationHours.isAcceptableOrUnknown(
          data['consultation_hours']!,
          _consultationHoursMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseMetadataEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      courseId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}course_id'],
          )!,
      classroomUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_url'],
      ),
      lmsUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lms_url'],
      ),
      profName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prof_name'],
      ),
      profEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prof_email'],
      ),
      consultationHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consultation_hours'],
      ),
    );
  }

  @override
  $CourseMetadataTable createAlias(String alias) {
    return $CourseMetadataTable(attachedDatabase, alias);
  }
}

class CourseMetadataEntry extends DataClass
    implements Insertable<CourseMetadataEntry> {
  final String id;
  final String courseId;
  final String? classroomUrl;
  final String? lmsUrl;
  final String? profName;
  final String? profEmail;
  final String? consultationHours;
  const CourseMetadataEntry({
    required this.id,
    required this.courseId,
    this.classroomUrl,
    this.lmsUrl,
    this.profName,
    this.profEmail,
    this.consultationHours,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    if (!nullToAbsent || classroomUrl != null) {
      map['classroom_url'] = Variable<String>(classroomUrl);
    }
    if (!nullToAbsent || lmsUrl != null) {
      map['lms_url'] = Variable<String>(lmsUrl);
    }
    if (!nullToAbsent || profName != null) {
      map['prof_name'] = Variable<String>(profName);
    }
    if (!nullToAbsent || profEmail != null) {
      map['prof_email'] = Variable<String>(profEmail);
    }
    if (!nullToAbsent || consultationHours != null) {
      map['consultation_hours'] = Variable<String>(consultationHours);
    }
    return map;
  }

  CourseMetadataCompanion toCompanion(bool nullToAbsent) {
    return CourseMetadataCompanion(
      id: Value(id),
      courseId: Value(courseId),
      classroomUrl:
          classroomUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(classroomUrl),
      lmsUrl:
          lmsUrl == null && nullToAbsent ? const Value.absent() : Value(lmsUrl),
      profName:
          profName == null && nullToAbsent
              ? const Value.absent()
              : Value(profName),
      profEmail:
          profEmail == null && nullToAbsent
              ? const Value.absent()
              : Value(profEmail),
      consultationHours:
          consultationHours == null && nullToAbsent
              ? const Value.absent()
              : Value(consultationHours),
    );
  }

  factory CourseMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseMetadataEntry(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      classroomUrl: serializer.fromJson<String?>(json['classroomUrl']),
      lmsUrl: serializer.fromJson<String?>(json['lmsUrl']),
      profName: serializer.fromJson<String?>(json['profName']),
      profEmail: serializer.fromJson<String?>(json['profEmail']),
      consultationHours: serializer.fromJson<String?>(
        json['consultationHours'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'classroomUrl': serializer.toJson<String?>(classroomUrl),
      'lmsUrl': serializer.toJson<String?>(lmsUrl),
      'profName': serializer.toJson<String?>(profName),
      'profEmail': serializer.toJson<String?>(profEmail),
      'consultationHours': serializer.toJson<String?>(consultationHours),
    };
  }

  CourseMetadataEntry copyWith({
    String? id,
    String? courseId,
    Value<String?> classroomUrl = const Value.absent(),
    Value<String?> lmsUrl = const Value.absent(),
    Value<String?> profName = const Value.absent(),
    Value<String?> profEmail = const Value.absent(),
    Value<String?> consultationHours = const Value.absent(),
  }) => CourseMetadataEntry(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    classroomUrl: classroomUrl.present ? classroomUrl.value : this.classroomUrl,
    lmsUrl: lmsUrl.present ? lmsUrl.value : this.lmsUrl,
    profName: profName.present ? profName.value : this.profName,
    profEmail: profEmail.present ? profEmail.value : this.profEmail,
    consultationHours:
        consultationHours.present
            ? consultationHours.value
            : this.consultationHours,
  );
  CourseMetadataEntry copyWithCompanion(CourseMetadataCompanion data) {
    return CourseMetadataEntry(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      classroomUrl:
          data.classroomUrl.present
              ? data.classroomUrl.value
              : this.classroomUrl,
      lmsUrl: data.lmsUrl.present ? data.lmsUrl.value : this.lmsUrl,
      profName: data.profName.present ? data.profName.value : this.profName,
      profEmail: data.profEmail.present ? data.profEmail.value : this.profEmail,
      consultationHours:
          data.consultationHours.present
              ? data.consultationHours.value
              : this.consultationHours,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseMetadataEntry(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('classroomUrl: $classroomUrl, ')
          ..write('lmsUrl: $lmsUrl, ')
          ..write('profName: $profName, ')
          ..write('profEmail: $profEmail, ')
          ..write('consultationHours: $consultationHours')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    classroomUrl,
    lmsUrl,
    profName,
    profEmail,
    consultationHours,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseMetadataEntry &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.classroomUrl == this.classroomUrl &&
          other.lmsUrl == this.lmsUrl &&
          other.profName == this.profName &&
          other.profEmail == this.profEmail &&
          other.consultationHours == this.consultationHours);
}

class CourseMetadataCompanion extends UpdateCompanion<CourseMetadataEntry> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String?> classroomUrl;
  final Value<String?> lmsUrl;
  final Value<String?> profName;
  final Value<String?> profEmail;
  final Value<String?> consultationHours;
  final Value<int> rowid;
  const CourseMetadataCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.classroomUrl = const Value.absent(),
    this.lmsUrl = const Value.absent(),
    this.profName = const Value.absent(),
    this.profEmail = const Value.absent(),
    this.consultationHours = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseMetadataCompanion.insert({
    required String id,
    required String courseId,
    this.classroomUrl = const Value.absent(),
    this.lmsUrl = const Value.absent(),
    this.profName = const Value.absent(),
    this.profEmail = const Value.absent(),
    this.consultationHours = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId);
  static Insertable<CourseMetadataEntry> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? classroomUrl,
    Expression<String>? lmsUrl,
    Expression<String>? profName,
    Expression<String>? profEmail,
    Expression<String>? consultationHours,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (classroomUrl != null) 'classroom_url': classroomUrl,
      if (lmsUrl != null) 'lms_url': lmsUrl,
      if (profName != null) 'prof_name': profName,
      if (profEmail != null) 'prof_email': profEmail,
      if (consultationHours != null) 'consultation_hours': consultationHours,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseMetadataCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String?>? classroomUrl,
    Value<String?>? lmsUrl,
    Value<String?>? profName,
    Value<String?>? profEmail,
    Value<String?>? consultationHours,
    Value<int>? rowid,
  }) {
    return CourseMetadataCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      classroomUrl: classroomUrl ?? this.classroomUrl,
      lmsUrl: lmsUrl ?? this.lmsUrl,
      profName: profName ?? this.profName,
      profEmail: profEmail ?? this.profEmail,
      consultationHours: consultationHours ?? this.consultationHours,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (classroomUrl.present) {
      map['classroom_url'] = Variable<String>(classroomUrl.value);
    }
    if (lmsUrl.present) {
      map['lms_url'] = Variable<String>(lmsUrl.value);
    }
    if (profName.present) {
      map['prof_name'] = Variable<String>(profName.value);
    }
    if (profEmail.present) {
      map['prof_email'] = Variable<String>(profEmail.value);
    }
    if (consultationHours.present) {
      map['consultation_hours'] = Variable<String>(consultationHours.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseMetadataCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('classroomUrl: $classroomUrl, ')
          ..write('lmsUrl: $lmsUrl, ')
          ..write('profName: $profName, ')
          ..write('profEmail: $profEmail, ')
          ..write('consultationHours: $consultationHours, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queueIdMeta = const VerificationMeta(
    'queueId',
  );
  @override
  late final GeneratedColumn<int> queueId = GeneratedColumn<int>(
    'queue_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    queueId,
    mutationId,
    targetTable,
    operation,
    payload,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('queue_id')) {
      context.handle(
        _queueIdMeta,
        queueId.isAcceptableOrUnknown(data['queue_id']!, _queueIdMeta),
      );
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['table_name']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queueId};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      queueId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}queue_id'],
          )!,
      mutationId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mutation_id'],
          )!,
      targetTable:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}table_name'],
          )!,
      operation:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}operation'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      retryCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}retry_count'],
          )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int queueId;
  final String mutationId;
  final String targetTable;
  final String operation;
  final String payload;
  final int retryCount;
  const SyncQueueEntry({
    required this.queueId,
    required this.mutationId,
    required this.targetTable,
    required this.operation,
    required this.payload,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['queue_id'] = Variable<int>(queueId);
    map['mutation_id'] = Variable<String>(mutationId);
    map['table_name'] = Variable<String>(targetTable);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      queueId: Value(queueId),
      mutationId: Value(mutationId),
      targetTable: Value(targetTable),
      operation: Value(operation),
      payload: Value(payload),
      retryCount: Value(retryCount),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      queueId: serializer.fromJson<int>(json['queueId']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'queueId': serializer.toJson<int>(queueId),
      'mutationId': serializer.toJson<String>(mutationId),
      'targetTable': serializer.toJson<String>(targetTable),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncQueueEntry copyWith({
    int? queueId,
    String? mutationId,
    String? targetTable,
    String? operation,
    String? payload,
    int? retryCount,
  }) => SyncQueueEntry(
    queueId: queueId ?? this.queueId,
    mutationId: mutationId ?? this.mutationId,
    targetTable: targetTable ?? this.targetTable,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    retryCount: retryCount ?? this.retryCount,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      queueId: data.queueId.present ? data.queueId.value : this.queueId,
      mutationId:
          data.mutationId.present ? data.mutationId.value : this.mutationId,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('queueId: $queueId, ')
          ..write('mutationId: $mutationId, ')
          ..write('targetTable: $targetTable, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    queueId,
    mutationId,
    targetTable,
    operation,
    payload,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.queueId == this.queueId &&
          other.mutationId == this.mutationId &&
          other.targetTable == this.targetTable &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> queueId;
  final Value<String> mutationId;
  final Value<String> targetTable;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> retryCount;
  const SyncQueueCompanion({
    this.queueId = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.queueId = const Value.absent(),
    required String mutationId,
    required String targetTable,
    required String operation,
    required String payload,
    this.retryCount = const Value.absent(),
  }) : mutationId = Value(mutationId),
       targetTable = Value(targetTable),
       operation = Value(operation),
       payload = Value(payload);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? queueId,
    Expression<String>? mutationId,
    Expression<String>? targetTable,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (queueId != null) 'queue_id': queueId,
      if (mutationId != null) 'mutation_id': mutationId,
      if (targetTable != null) 'table_name': targetTable,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? queueId,
    Value<String>? mutationId,
    Value<String>? targetTable,
    Value<String>? operation,
    Value<String>? payload,
    Value<int>? retryCount,
  }) {
    return SyncQueueCompanion(
      queueId: queueId ?? this.queueId,
      mutationId: mutationId ?? this.mutationId,
      targetTable: targetTable ?? this.targetTable,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queueId.present) {
      map['queue_id'] = Variable<int>(queueId.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (targetTable.present) {
      map['table_name'] = Variable<String>(targetTable.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('queueId: $queueId, ')
          ..write('mutationId: $mutationId, ')
          ..write('targetTable: $targetTable, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $CampusPinsTable extends CampusPins
    with TableInfo<$CampusPinsTable, CampusPin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CampusPinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roomCodeMeta = const VerificationMeta(
    'roomCode',
  );
  @override
  late final GeneratedColumn<String> roomCode = GeneratedColumn<String>(
    'room_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildingNameMeta = const VerificationMeta(
    'buildingName',
  );
  @override
  late final GeneratedColumn<String> buildingName = GeneratedColumn<String>(
    'building_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinColorMeta = const VerificationMeta(
    'pinColor',
  );
  @override
  late final GeneratedColumn<String> pinColor = GeneratedColumn<String>(
    'pin_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    roomCode,
    buildingName,
    latitude,
    longitude,
    pinColor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'campus_pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CampusPin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('room_code')) {
      context.handle(
        _roomCodeMeta,
        roomCode.isAcceptableOrUnknown(data['room_code']!, _roomCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roomCodeMeta);
    }
    if (data.containsKey('building_name')) {
      context.handle(
        _buildingNameMeta,
        buildingName.isAcceptableOrUnknown(
          data['building_name']!,
          _buildingNameMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('pin_color')) {
      context.handle(
        _pinColorMeta,
        pinColor.isAcceptableOrUnknown(data['pin_color']!, _pinColorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CampusPin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CampusPin(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      profileId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}profile_id'],
          )!,
      roomCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}room_code'],
          )!,
      buildingName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}building_name'],
      ),
      latitude:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}latitude'],
          )!,
      longitude:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}longitude'],
          )!,
      pinColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_color'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CampusPinsTable createAlias(String alias) {
    return $CampusPinsTable(attachedDatabase, alias);
  }
}

class CampusPin extends DataClass implements Insertable<CampusPin> {
  final String id;
  final String profileId;
  final String roomCode;
  final String? buildingName;
  final double latitude;
  final double longitude;
  final String? pinColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CampusPin({
    required this.id,
    required this.profileId,
    required this.roomCode,
    this.buildingName,
    required this.latitude,
    required this.longitude,
    this.pinColor,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['room_code'] = Variable<String>(roomCode);
    if (!nullToAbsent || buildingName != null) {
      map['building_name'] = Variable<String>(buildingName);
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || pinColor != null) {
      map['pin_color'] = Variable<String>(pinColor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CampusPinsCompanion toCompanion(bool nullToAbsent) {
    return CampusPinsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      roomCode: Value(roomCode),
      buildingName:
          buildingName == null && nullToAbsent
              ? const Value.absent()
              : Value(buildingName),
      latitude: Value(latitude),
      longitude: Value(longitude),
      pinColor:
          pinColor == null && nullToAbsent
              ? const Value.absent()
              : Value(pinColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CampusPin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CampusPin(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      roomCode: serializer.fromJson<String>(json['roomCode']),
      buildingName: serializer.fromJson<String?>(json['buildingName']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      pinColor: serializer.fromJson<String?>(json['pinColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'roomCode': serializer.toJson<String>(roomCode),
      'buildingName': serializer.toJson<String?>(buildingName),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'pinColor': serializer.toJson<String?>(pinColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CampusPin copyWith({
    String? id,
    String? profileId,
    String? roomCode,
    Value<String?> buildingName = const Value.absent(),
    double? latitude,
    double? longitude,
    Value<String?> pinColor = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CampusPin(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    roomCode: roomCode ?? this.roomCode,
    buildingName: buildingName.present ? buildingName.value : this.buildingName,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    pinColor: pinColor.present ? pinColor.value : this.pinColor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CampusPin copyWithCompanion(CampusPinsCompanion data) {
    return CampusPin(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      roomCode: data.roomCode.present ? data.roomCode.value : this.roomCode,
      buildingName:
          data.buildingName.present
              ? data.buildingName.value
              : this.buildingName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      pinColor: data.pinColor.present ? data.pinColor.value : this.pinColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CampusPin(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('roomCode: $roomCode, ')
          ..write('buildingName: $buildingName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('pinColor: $pinColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    roomCode,
    buildingName,
    latitude,
    longitude,
    pinColor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CampusPin &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.roomCode == this.roomCode &&
          other.buildingName == this.buildingName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.pinColor == this.pinColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CampusPinsCompanion extends UpdateCompanion<CampusPin> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> roomCode;
  final Value<String?> buildingName;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> pinColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CampusPinsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.roomCode = const Value.absent(),
    this.buildingName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.pinColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CampusPinsCompanion.insert({
    required String id,
    required String profileId,
    required String roomCode,
    this.buildingName = const Value.absent(),
    required double latitude,
    required double longitude,
    this.pinColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       roomCode = Value(roomCode),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<CampusPin> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? roomCode,
    Expression<String>? buildingName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? pinColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (roomCode != null) 'room_code': roomCode,
      if (buildingName != null) 'building_name': buildingName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (pinColor != null) 'pin_color': pinColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CampusPinsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? roomCode,
    Value<String?>? buildingName,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? pinColor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CampusPinsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      roomCode: roomCode ?? this.roomCode,
      buildingName: buildingName ?? this.buildingName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pinColor: pinColor ?? this.pinColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (roomCode.present) {
      map['room_code'] = Variable<String>(roomCode.value);
    }
    if (buildingName.present) {
      map['building_name'] = Variable<String>(buildingName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (pinColor.present) {
      map['pin_color'] = Variable<String>(pinColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CampusPinsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('roomCode: $roomCode, ')
          ..write('buildingName: $buildingName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('pinColor: $pinColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AcademicProfilesTable academicProfiles = $AcademicProfilesTable(
    this,
  );
  late final $CoursesTable courses = $CoursesTable(this);
  late final $CourseSchedulesTable courseSchedules = $CourseSchedulesTable(
    this,
  );
  late final $CourseTasksTable courseTasks = $CourseTasksTable(this);
  late final $CourseMetadataTable courseMetadata = $CourseMetadataTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CampusPinsTable campusPins = $CampusPinsTable(this);
  late final Index idxCoursesProfileCode = Index(
    'idx_courses_profile_code',
    'CREATE UNIQUE INDEX idx_courses_profile_code ON courses (profile_id, course_code)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    academicProfiles,
    courses,
    courseSchedules,
    courseTasks,
    courseMetadata,
    syncQueue,
    campusPins,
    idxCoursesProfileCode,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('courses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'courses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_schedules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'courses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'courses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_metadata', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('campus_pins', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AcademicProfilesTableCreateCompanionBuilder =
    AcademicProfilesCompanion Function({
      required String id,
      required String studentNo,
      required String section,
      required String schoolYear,
      required String semester,
      required double totalUnits,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AcademicProfilesTableUpdateCompanionBuilder =
    AcademicProfilesCompanion Function({
      Value<String> id,
      Value<String> studentNo,
      Value<String> section,
      Value<String> schoolYear,
      Value<String> semester,
      Value<double> totalUnits,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AcademicProfilesTableReferences
    extends
        BaseReferences<_$AppDatabase, $AcademicProfilesTable, AcademicProfile> {
  $$AcademicProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CoursesTable, List<Course>> _coursesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.courses,
    aliasName: 'academic_profiles__id__courses__profile_id',
  );

  $$CoursesTableProcessedTableManager get coursesRefs {
    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_coursesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CampusPinsTable, List<CampusPin>>
  _campusPinsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.campusPins,
    aliasName: 'academic_profiles__id__campus_pins__profile_id',
  );

  $$CampusPinsTableProcessedTableManager get campusPinsRefs {
    final manager = $$CampusPinsTableTableManager(
      $_db,
      $_db.campusPins,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_campusPinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AcademicProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $AcademicProfilesTable> {
  $$AcademicProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentNo => $composableBuilder(
    column: $table.studentNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> coursesRefs(
    Expression<bool> Function($$CoursesTableFilterComposer f) f,
  ) {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> campusPinsRefs(
    Expression<bool> Function($$CampusPinsTableFilterComposer f) f,
  ) {
    final $$CampusPinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.campusPins,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CampusPinsTableFilterComposer(
            $db: $db,
            $table: $db.campusPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AcademicProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $AcademicProfilesTable> {
  $$AcademicProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentNo => $composableBuilder(
    column: $table.studentNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AcademicProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcademicProfilesTable> {
  $$AcademicProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentNo =>
      $composableBuilder(column: $table.studentNo, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<double> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> coursesRefs<T extends Object>(
    Expression<T> Function($$CoursesTableAnnotationComposer a) f,
  ) {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> campusPinsRefs<T extends Object>(
    Expression<T> Function($$CampusPinsTableAnnotationComposer a) f,
  ) {
    final $$CampusPinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.campusPins,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CampusPinsTableAnnotationComposer(
            $db: $db,
            $table: $db.campusPins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AcademicProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AcademicProfilesTable,
          AcademicProfile,
          $$AcademicProfilesTableFilterComposer,
          $$AcademicProfilesTableOrderingComposer,
          $$AcademicProfilesTableAnnotationComposer,
          $$AcademicProfilesTableCreateCompanionBuilder,
          $$AcademicProfilesTableUpdateCompanionBuilder,
          (AcademicProfile, $$AcademicProfilesTableReferences),
          AcademicProfile,
          PrefetchHooks Function({bool coursesRefs, bool campusPinsRefs})
        > {
  $$AcademicProfilesTableTableManager(
    _$AppDatabase db,
    $AcademicProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$AcademicProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AcademicProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$AcademicProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> studentNo = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> schoolYear = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<double> totalUnits = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AcademicProfilesCompanion(
                id: id,
                studentNo: studentNo,
                section: section,
                schoolYear: schoolYear,
                semester: semester,
                totalUnits: totalUnits,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String studentNo,
                required String section,
                required String schoolYear,
                required String semester,
                required double totalUnits,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AcademicProfilesCompanion.insert(
                id: id,
                studentNo: studentNo,
                section: section,
                schoolYear: schoolYear,
                semester: semester,
                totalUnits: totalUnits,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$AcademicProfilesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            coursesRefs = false,
            campusPinsRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (coursesRefs) db.courses,
                if (campusPinsRefs) db.campusPins,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (coursesRefs)
                    await $_getPrefetchedData<
                      AcademicProfile,
                      $AcademicProfilesTable,
                      Course
                    >(
                      currentTable: table,
                      referencedTable: $$AcademicProfilesTableReferences
                          ._coursesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$AcademicProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).coursesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.profileId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (campusPinsRefs)
                    await $_getPrefetchedData<
                      AcademicProfile,
                      $AcademicProfilesTable,
                      CampusPin
                    >(
                      currentTable: table,
                      referencedTable: $$AcademicProfilesTableReferences
                          ._campusPinsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$AcademicProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).campusPinsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.profileId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AcademicProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AcademicProfilesTable,
      AcademicProfile,
      $$AcademicProfilesTableFilterComposer,
      $$AcademicProfilesTableOrderingComposer,
      $$AcademicProfilesTableAnnotationComposer,
      $$AcademicProfilesTableCreateCompanionBuilder,
      $$AcademicProfilesTableUpdateCompanionBuilder,
      (AcademicProfile, $$AcademicProfilesTableReferences),
      AcademicProfile,
      PrefetchHooks Function({bool coursesRefs, bool campusPinsRefs})
    >;
typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      required String id,
      required String profileId,
      required String courseCode,
      required String courseTitle,
      Value<double> lecUnits,
      Value<double> labUnits,
      Value<bool> isArchived,
      Value<int> rowid,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> courseCode,
      Value<String> courseTitle,
      Value<double> lecUnits,
      Value<double> labUnits,
      Value<bool> isArchived,
      Value<int> rowid,
    });

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, Course> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AcademicProfilesTable _profileIdTable(_$AppDatabase db) => db
      .academicProfiles
      .createAlias('courses__profile_id__academic_profiles__id');

  $$AcademicProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$AcademicProfilesTableTableManager(
      $_db,
      $_db.academicProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CourseSchedulesTable, List<CourseSchedule>>
  _courseSchedulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseSchedules,
    aliasName: 'courses__id__course_schedules__course_id',
  );

  $$CourseSchedulesTableProcessedTableManager get courseSchedulesRefs {
    final manager = $$CourseSchedulesTableTableManager(
      $_db,
      $_db.courseSchedules,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseSchedulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CourseTasksTable, List<CourseTask>>
  _courseTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseTasks,
    aliasName: 'courses__id__course_tasks__course_id',
  );

  $$CourseTasksTableProcessedTableManager get courseTasksRefs {
    final manager = $$CourseTasksTableTableManager(
      $_db,
      $_db.courseTasks,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CourseMetadataTable, List<CourseMetadataEntry>>
  _courseMetadataRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseMetadata,
    aliasName: 'courses__id__course_metadata__course_id',
  );

  $$CourseMetadataTableProcessedTableManager get courseMetadataRefs {
    final manager = $$CourseMetadataTableTableManager(
      $_db,
      $_db.courseMetadata,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseMetadataRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseCode => $composableBuilder(
    column: $table.courseCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseTitle => $composableBuilder(
    column: $table.courseTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lecUnits => $composableBuilder(
    column: $table.lecUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get labUnits => $composableBuilder(
    column: $table.labUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicProfilesTableFilterComposer get profileId {
    final $$AcademicProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.academicProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicProfilesTableFilterComposer(
            $db: $db,
            $table: $db.academicProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> courseSchedulesRefs(
    Expression<bool> Function($$CourseSchedulesTableFilterComposer f) f,
  ) {
    final $$CourseSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSchedules,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.courseSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> courseTasksRefs(
    Expression<bool> Function($$CourseTasksTableFilterComposer f) f,
  ) {
    final $$CourseTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseTasks,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseTasksTableFilterComposer(
            $db: $db,
            $table: $db.courseTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> courseMetadataRefs(
    Expression<bool> Function($$CourseMetadataTableFilterComposer f) f,
  ) {
    final $$CourseMetadataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseMetadata,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseMetadataTableFilterComposer(
            $db: $db,
            $table: $db.courseMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseCode => $composableBuilder(
    column: $table.courseCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseTitle => $composableBuilder(
    column: $table.courseTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lecUnits => $composableBuilder(
    column: $table.lecUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get labUnits => $composableBuilder(
    column: $table.labUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicProfilesTableOrderingComposer get profileId {
    final $$AcademicProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.academicProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.academicProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseCode => $composableBuilder(
    column: $table.courseCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get courseTitle => $composableBuilder(
    column: $table.courseTitle,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lecUnits =>
      $composableBuilder(column: $table.lecUnits, builder: (column) => column);

  GeneratedColumn<double> get labUnits =>
      $composableBuilder(column: $table.labUnits, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  $$AcademicProfilesTableAnnotationComposer get profileId {
    final $$AcademicProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.academicProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.academicProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> courseSchedulesRefs<T extends Object>(
    Expression<T> Function($$CourseSchedulesTableAnnotationComposer a) f,
  ) {
    final $$CourseSchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSchedules,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.courseSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> courseTasksRefs<T extends Object>(
    Expression<T> Function($$CourseTasksTableAnnotationComposer a) f,
  ) {
    final $$CourseTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseTasks,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.courseTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> courseMetadataRefs<T extends Object>(
    Expression<T> Function($$CourseMetadataTableAnnotationComposer a) f,
  ) {
    final $$CourseMetadataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseMetadata,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseMetadataTableAnnotationComposer(
            $db: $db,
            $table: $db.courseMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          Course,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (Course, $$CoursesTableReferences),
          Course,
          PrefetchHooks Function({
            bool profileId,
            bool courseSchedulesRefs,
            bool courseTasksRefs,
            bool courseMetadataRefs,
          })
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> courseCode = const Value.absent(),
                Value<String> courseTitle = const Value.absent(),
                Value<double> lecUnits = const Value.absent(),
                Value<double> labUnits = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                profileId: profileId,
                courseCode: courseCode,
                courseTitle: courseTitle,
                lecUnits: lecUnits,
                labUnits: labUnits,
                isArchived: isArchived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String courseCode,
                required String courseTitle,
                Value<double> lecUnits = const Value.absent(),
                Value<double> labUnits = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                profileId: profileId,
                courseCode: courseCode,
                courseTitle: courseTitle,
                lecUnits: lecUnits,
                labUnits: labUnits,
                isArchived: isArchived,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$CoursesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            profileId = false,
            courseSchedulesRefs = false,
            courseTasksRefs = false,
            courseMetadataRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseSchedulesRefs) db.courseSchedules,
                if (courseTasksRefs) db.courseTasks,
                if (courseMetadataRefs) db.courseMetadata,
              ],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (profileId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.profileId,
                            referencedTable: $$CoursesTableReferences
                                ._profileIdTable(db),
                            referencedColumn:
                                $$CoursesTableReferences._profileIdTable(db).id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseSchedulesRefs)
                    await $_getPrefetchedData<
                      Course,
                      $CoursesTable,
                      CourseSchedule
                    >(
                      currentTable: table,
                      referencedTable: $$CoursesTableReferences
                          ._courseSchedulesRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).courseSchedulesRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.courseId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (courseTasksRefs)
                    await $_getPrefetchedData<
                      Course,
                      $CoursesTable,
                      CourseTask
                    >(
                      currentTable: table,
                      referencedTable: $$CoursesTableReferences
                          ._courseTasksRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).courseTasksRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.courseId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (courseMetadataRefs)
                    await $_getPrefetchedData<
                      Course,
                      $CoursesTable,
                      CourseMetadataEntry
                    >(
                      currentTable: table,
                      referencedTable: $$CoursesTableReferences
                          ._courseMetadataRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).courseMetadataRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.courseId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      Course,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (Course, $$CoursesTableReferences),
      Course,
      PrefetchHooks Function({
        bool profileId,
        bool courseSchedulesRefs,
        bool courseTasksRefs,
        bool courseMetadataRefs,
      })
    >;
typedef $$CourseSchedulesTableCreateCompanionBuilder =
    CourseSchedulesCompanion Function({
      required String id,
      required String courseId,
      required String dayToken,
      required int startMinutes,
      required int endMinutes,
      required String roomCode,
      required String sessionType,
      Value<bool> isTba,
      Value<int> rowid,
    });
typedef $$CourseSchedulesTableUpdateCompanionBuilder =
    CourseSchedulesCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String> dayToken,
      Value<int> startMinutes,
      Value<int> endMinutes,
      Value<String> roomCode,
      Value<String> sessionType,
      Value<bool> isTba,
      Value<int> rowid,
    });

final class $$CourseSchedulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CourseSchedulesTable, CourseSchedule> {
  $$CourseSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('course_schedules__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $CourseSchedulesTable> {
  $$CourseSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayToken => $composableBuilder(
    column: $table.dayToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTba => $composableBuilder(
    column: $table.isTba,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseSchedulesTable> {
  $$CourseSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayToken => $composableBuilder(
    column: $table.dayToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTba => $composableBuilder(
    column: $table.isTba,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseSchedulesTable> {
  $$CourseSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dayToken =>
      $composableBuilder(column: $table.dayToken, builder: (column) => column);

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinutes => $composableBuilder(
    column: $table.endMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roomCode =>
      $composableBuilder(column: $table.roomCode, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTba =>
      $composableBuilder(column: $table.isTba, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseSchedulesTable,
          CourseSchedule,
          $$CourseSchedulesTableFilterComposer,
          $$CourseSchedulesTableOrderingComposer,
          $$CourseSchedulesTableAnnotationComposer,
          $$CourseSchedulesTableCreateCompanionBuilder,
          $$CourseSchedulesTableUpdateCompanionBuilder,
          (CourseSchedule, $$CourseSchedulesTableReferences),
          CourseSchedule,
          PrefetchHooks Function({bool courseId})
        > {
  $$CourseSchedulesTableTableManager(
    _$AppDatabase db,
    $CourseSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CourseSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CourseSchedulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CourseSchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> dayToken = const Value.absent(),
                Value<int> startMinutes = const Value.absent(),
                Value<int> endMinutes = const Value.absent(),
                Value<String> roomCode = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<bool> isTba = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseSchedulesCompanion(
                id: id,
                courseId: courseId,
                dayToken: dayToken,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                roomCode: roomCode,
                sessionType: sessionType,
                isTba: isTba,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required String dayToken,
                required int startMinutes,
                required int endMinutes,
                required String roomCode,
                required String sessionType,
                Value<bool> isTba = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseSchedulesCompanion.insert(
                id: id,
                courseId: courseId,
                dayToken: dayToken,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                roomCode: roomCode,
                sessionType: sessionType,
                isTba: isTba,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$CourseSchedulesTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (courseId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.courseId,
                            referencedTable: $$CourseSchedulesTableReferences
                                ._courseIdTable(db),
                            referencedColumn:
                                $$CourseSchedulesTableReferences
                                    ._courseIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseSchedulesTable,
      CourseSchedule,
      $$CourseSchedulesTableFilterComposer,
      $$CourseSchedulesTableOrderingComposer,
      $$CourseSchedulesTableAnnotationComposer,
      $$CourseSchedulesTableCreateCompanionBuilder,
      $$CourseSchedulesTableUpdateCompanionBuilder,
      (CourseSchedule, $$CourseSchedulesTableReferences),
      CourseSchedule,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$CourseTasksTableCreateCompanionBuilder =
    CourseTasksCompanion Function({
      required String id,
      required String courseId,
      required String title,
      Value<String?> details,
      required String taskType,
      Value<bool> isCompleted,
      Value<DateTime?> dueDate,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CourseTasksTableUpdateCompanionBuilder =
    CourseTasksCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String> title,
      Value<String?> details,
      Value<String> taskType,
      Value<bool> isCompleted,
      Value<DateTime?> dueDate,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CourseTasksTableReferences
    extends BaseReferences<_$AppDatabase, $CourseTasksTable, CourseTask> {
  $$CourseTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('course_tasks__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseTasksTableFilterComposer
    extends Composer<_$AppDatabase, $CourseTasksTable> {
  $$CourseTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseTasksTable> {
  $$CourseTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseTasksTable> {
  $$CourseTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseTasksTable,
          CourseTask,
          $$CourseTasksTableFilterComposer,
          $$CourseTasksTableOrderingComposer,
          $$CourseTasksTableAnnotationComposer,
          $$CourseTasksTableCreateCompanionBuilder,
          $$CourseTasksTableUpdateCompanionBuilder,
          (CourseTask, $$CourseTasksTableReferences),
          CourseTask,
          PrefetchHooks Function({bool courseId})
        > {
  $$CourseTasksTableTableManager(_$AppDatabase db, $CourseTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CourseTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CourseTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$CourseTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseTasksCompanion(
                id: id,
                courseId: courseId,
                title: title,
                details: details,
                taskType: taskType,
                isCompleted: isCompleted,
                dueDate: dueDate,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required String title,
                Value<String?> details = const Value.absent(),
                required String taskType,
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseTasksCompanion.insert(
                id: id,
                courseId: courseId,
                title: title,
                details: details,
                taskType: taskType,
                isCompleted: isCompleted,
                dueDate: dueDate,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$CourseTasksTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (courseId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.courseId,
                            referencedTable: $$CourseTasksTableReferences
                                ._courseIdTable(db),
                            referencedColumn:
                                $$CourseTasksTableReferences
                                    ._courseIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseTasksTable,
      CourseTask,
      $$CourseTasksTableFilterComposer,
      $$CourseTasksTableOrderingComposer,
      $$CourseTasksTableAnnotationComposer,
      $$CourseTasksTableCreateCompanionBuilder,
      $$CourseTasksTableUpdateCompanionBuilder,
      (CourseTask, $$CourseTasksTableReferences),
      CourseTask,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$CourseMetadataTableCreateCompanionBuilder =
    CourseMetadataCompanion Function({
      required String id,
      required String courseId,
      Value<String?> classroomUrl,
      Value<String?> lmsUrl,
      Value<String?> profName,
      Value<String?> profEmail,
      Value<String?> consultationHours,
      Value<int> rowid,
    });
typedef $$CourseMetadataTableUpdateCompanionBuilder =
    CourseMetadataCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String?> classroomUrl,
      Value<String?> lmsUrl,
      Value<String?> profName,
      Value<String?> profEmail,
      Value<String?> consultationHours,
      Value<int> rowid,
    });

final class $$CourseMetadataTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CourseMetadataTable,
          CourseMetadataEntry
        > {
  $$CourseMetadataTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('course_metadata__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $CourseMetadataTable> {
  $$CourseMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classroomUrl => $composableBuilder(
    column: $table.classroomUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lmsUrl => $composableBuilder(
    column: $table.lmsUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profName => $composableBuilder(
    column: $table.profName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profEmail => $composableBuilder(
    column: $table.profEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consultationHours => $composableBuilder(
    column: $table.consultationHours,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseMetadataTable> {
  $$CourseMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classroomUrl => $composableBuilder(
    column: $table.classroomUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lmsUrl => $composableBuilder(
    column: $table.lmsUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profName => $composableBuilder(
    column: $table.profName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profEmail => $composableBuilder(
    column: $table.profEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consultationHours => $composableBuilder(
    column: $table.consultationHours,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseMetadataTable> {
  $$CourseMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get classroomUrl => $composableBuilder(
    column: $table.classroomUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lmsUrl =>
      $composableBuilder(column: $table.lmsUrl, builder: (column) => column);

  GeneratedColumn<String> get profName =>
      $composableBuilder(column: $table.profName, builder: (column) => column);

  GeneratedColumn<String> get profEmail =>
      $composableBuilder(column: $table.profEmail, builder: (column) => column);

  GeneratedColumn<String> get consultationHours => $composableBuilder(
    column: $table.consultationHours,
    builder: (column) => column,
  );

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseMetadataTable,
          CourseMetadataEntry,
          $$CourseMetadataTableFilterComposer,
          $$CourseMetadataTableOrderingComposer,
          $$CourseMetadataTableAnnotationComposer,
          $$CourseMetadataTableCreateCompanionBuilder,
          $$CourseMetadataTableUpdateCompanionBuilder,
          (CourseMetadataEntry, $$CourseMetadataTableReferences),
          CourseMetadataEntry,
          PrefetchHooks Function({bool courseId})
        > {
  $$CourseMetadataTableTableManager(
    _$AppDatabase db,
    $CourseMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CourseMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$CourseMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CourseMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String?> classroomUrl = const Value.absent(),
                Value<String?> lmsUrl = const Value.absent(),
                Value<String?> profName = const Value.absent(),
                Value<String?> profEmail = const Value.absent(),
                Value<String?> consultationHours = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseMetadataCompanion(
                id: id,
                courseId: courseId,
                classroomUrl: classroomUrl,
                lmsUrl: lmsUrl,
                profName: profName,
                profEmail: profEmail,
                consultationHours: consultationHours,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                Value<String?> classroomUrl = const Value.absent(),
                Value<String?> lmsUrl = const Value.absent(),
                Value<String?> profName = const Value.absent(),
                Value<String?> profEmail = const Value.absent(),
                Value<String?> consultationHours = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseMetadataCompanion.insert(
                id: id,
                courseId: courseId,
                classroomUrl: classroomUrl,
                lmsUrl: lmsUrl,
                profName: profName,
                profEmail: profEmail,
                consultationHours: consultationHours,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$CourseMetadataTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (courseId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.courseId,
                            referencedTable: $$CourseMetadataTableReferences
                                ._courseIdTable(db),
                            referencedColumn:
                                $$CourseMetadataTableReferences
                                    ._courseIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseMetadataTable,
      CourseMetadataEntry,
      $$CourseMetadataTableFilterComposer,
      $$CourseMetadataTableOrderingComposer,
      $$CourseMetadataTableAnnotationComposer,
      $$CourseMetadataTableCreateCompanionBuilder,
      $$CourseMetadataTableUpdateCompanionBuilder,
      (CourseMetadataEntry, $$CourseMetadataTableReferences),
      CourseMetadataEntry,
      PrefetchHooks Function({bool courseId})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> queueId,
      required String mutationId,
      required String targetTable,
      required String operation,
      required String payload,
      Value<int> retryCount,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> queueId,
      Value<String> mutationId,
      Value<String> targetTable,
      Value<String> operation,
      Value<String> payload,
      Value<int> retryCount,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get queueId => $composableBuilder(
    column: $table.queueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get queueId => $composableBuilder(
    column: $table.queueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get queueId =>
      $composableBuilder(column: $table.queueId, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> queueId = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncQueueCompanion(
                queueId: queueId,
                mutationId: mutationId,
                targetTable: targetTable,
                operation: operation,
                payload: payload,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> queueId = const Value.absent(),
                required String mutationId,
                required String targetTable,
                required String operation,
                required String payload,
                Value<int> retryCount = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                queueId: queueId,
                mutationId: mutationId,
                targetTable: targetTable,
                operation: operation,
                payload: payload,
                retryCount: retryCount,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$CampusPinsTableCreateCompanionBuilder =
    CampusPinsCompanion Function({
      required String id,
      required String profileId,
      required String roomCode,
      Value<String?> buildingName,
      required double latitude,
      required double longitude,
      Value<String?> pinColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CampusPinsTableUpdateCompanionBuilder =
    CampusPinsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> roomCode,
      Value<String?> buildingName,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> pinColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CampusPinsTableReferences
    extends BaseReferences<_$AppDatabase, $CampusPinsTable, CampusPin> {
  $$CampusPinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AcademicProfilesTable _profileIdTable(_$AppDatabase db) => db
      .academicProfiles
      .createAlias('campus_pins__profile_id__academic_profiles__id');

  $$AcademicProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$AcademicProfilesTableTableManager(
      $_db,
      $_db.academicProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CampusPinsTableFilterComposer
    extends Composer<_$AppDatabase, $CampusPinsTable> {
  $$CampusPinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buildingName => $composableBuilder(
    column: $table.buildingName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinColor => $composableBuilder(
    column: $table.pinColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicProfilesTableFilterComposer get profileId {
    final $$AcademicProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.academicProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicProfilesTableFilterComposer(
            $db: $db,
            $table: $db.academicProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CampusPinsTableOrderingComposer
    extends Composer<_$AppDatabase, $CampusPinsTable> {
  $$CampusPinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buildingName => $composableBuilder(
    column: $table.buildingName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinColor => $composableBuilder(
    column: $table.pinColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicProfilesTableOrderingComposer get profileId {
    final $$AcademicProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.academicProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.academicProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CampusPinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CampusPinsTable> {
  $$CampusPinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomCode =>
      $composableBuilder(column: $table.roomCode, builder: (column) => column);

  GeneratedColumn<String> get buildingName => $composableBuilder(
    column: $table.buildingName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get pinColor =>
      $composableBuilder(column: $table.pinColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AcademicProfilesTableAnnotationComposer get profileId {
    final $$AcademicProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.academicProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.academicProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CampusPinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CampusPinsTable,
          CampusPin,
          $$CampusPinsTableFilterComposer,
          $$CampusPinsTableOrderingComposer,
          $$CampusPinsTableAnnotationComposer,
          $$CampusPinsTableCreateCompanionBuilder,
          $$CampusPinsTableUpdateCompanionBuilder,
          (CampusPin, $$CampusPinsTableReferences),
          CampusPin,
          PrefetchHooks Function({bool profileId})
        > {
  $$CampusPinsTableTableManager(_$AppDatabase db, $CampusPinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CampusPinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CampusPinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CampusPinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> roomCode = const Value.absent(),
                Value<String?> buildingName = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> pinColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CampusPinsCompanion(
                id: id,
                profileId: profileId,
                roomCode: roomCode,
                buildingName: buildingName,
                latitude: latitude,
                longitude: longitude,
                pinColor: pinColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String roomCode,
                Value<String?> buildingName = const Value.absent(),
                required double latitude,
                required double longitude,
                Value<String?> pinColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CampusPinsCompanion.insert(
                id: id,
                profileId: profileId,
                roomCode: roomCode,
                buildingName: buildingName,
                latitude: latitude,
                longitude: longitude,
                pinColor: pinColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$CampusPinsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (profileId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.profileId,
                            referencedTable: $$CampusPinsTableReferences
                                ._profileIdTable(db),
                            referencedColumn:
                                $$CampusPinsTableReferences
                                    ._profileIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CampusPinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CampusPinsTable,
      CampusPin,
      $$CampusPinsTableFilterComposer,
      $$CampusPinsTableOrderingComposer,
      $$CampusPinsTableAnnotationComposer,
      $$CampusPinsTableCreateCompanionBuilder,
      $$CampusPinsTableUpdateCompanionBuilder,
      (CampusPin, $$CampusPinsTableReferences),
      CampusPin,
      PrefetchHooks Function({bool profileId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AcademicProfilesTableTableManager get academicProfiles =>
      $$AcademicProfilesTableTableManager(_db, _db.academicProfiles);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$CourseSchedulesTableTableManager get courseSchedules =>
      $$CourseSchedulesTableTableManager(_db, _db.courseSchedules);
  $$CourseTasksTableTableManager get courseTasks =>
      $$CourseTasksTableTableManager(_db, _db.courseTasks);
  $$CourseMetadataTableTableManager get courseMetadata =>
      $$CourseMetadataTableTableManager(_db, _db.courseMetadata);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CampusPinsTableTableManager get campusPins =>
      $$CampusPinsTableTableManager(_db, _db.campusPins);
}
