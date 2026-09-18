import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/utils/time_formatter.dart';
import '../models/parsed_cor.dart';

/// Service providing Cloud AI (Gemini) fallback for complex, non-standard, or irregular COR schedules.
/// Routes requests through Supabase Edge Functions for centralized key security with direct API fallback.
class GeminiCorParserService {
  static const String _systemPrompt = '''
You are an expert academic schedule and Certificate of Registration (COR) extraction engine.
Your task is to analyze the document text (which may be from a university COR, syllabus, curriculum, or weekly class schedule) and extract all course subjects, class hours, days, rooms, and student metadata into a strict JSON format.

JSON Schema:
{
  "studentNo": "Student ID or empty string",
  "section": "Section name e.g. BSCS 3-1 or empty string",
  "schoolYear": "Academic year e.g. 2025-2026 or empty string",
  "semester": "Semester e.g. 1st Semester or empty string",
  "totalUnits": 0.0,
  "courses": [
    {
      "courseCode": "Course/Subject code e.g. CS101, DCIT 24, MATH 1",
      "courseTitle": "Descriptive course title",
      "instructor": "Instructor / Professor name (e.g. Prof. Juan Dela Cruz) or empty string",
      "lecUnits": 2.0,
      "labUnits": 1.0,
      "schedules": [
        {
          "dayToken": "M or T or W or TH or F or S",
          "startMinutes": 420,
          "endMinutes": 540,
          "startTime": "07:00 AM",
          "endTime": "09:00 AM",
          "roomCode": "Room name e.g. CL1, 403B, or TBA",
          "sessionType": "lecture or lab",
          "isTba": false
        }
      ]
    }
  ]
}

Extraction Rules:
1. dayToken MUST be one of: "M" (Monday), "T" (Tuesday), "W" (Wednesday), "TH" (Thursday), "F" (Friday), "S" (Saturday).
   If a course meets on multiple days (e.g. M/TH, MW, TTH, Mon/Wed), split into separate schedule entries in the "schedules" array.
2. startMinutes and endMinutes are integers representing minutes from midnight:
   - 7:00 AM -> 420
   - 7:30 AM -> 450
   - 9:00 AM -> 540
   - 10:00 AM -> 600
   - 1:00 PM (13:00) -> 780
   - 2:30 PM (14:30) -> 870
   - 5:30 PM (17:30) -> 1050
3. If course code is not explicitly labeled, use the subject title as the courseCode.
4. Output ONLY the raw valid JSON object. No conversational preamble, no markdown comments outside the JSON.
''';

  // Rotation State Tracker (Reset at midnight each day)
  static int _currentModelIndex = 0;
  static DateTime? _lastRotationDate;

  /// Transforms internal API model identifier to branded public name for UI & logs (e.g. gemini-3.1-flash-lite -> sembase-3.1-flash-lite)
  static String toPublicModelName(String modelId) {
    return modelId.replaceAll('gemini-', 'sembase-');
  }

  /// Current active model index in the rotation cascade
  static int get currentModelIndex => _getEffectiveModelIndex();

  /// Current active model backend name
  static String get activeModelName {
    final cascade = AppConfig.geminiModelRotationCascade;
    final index = _getEffectiveModelIndex();
    return cascade[index % cascade.length];
  }

  /// Current active model user-facing branded name
  static String get activePublicModelName {
    return toPublicModelName(activeModelName);
  }

  /// Resets rotation index back to 0 (Useful for test suites or manual user reset)
  static void resetRotationForTesting() {
    _currentModelIndex = 0;
    _lastRotationDate = DateTime.now();
  }

  /// Manually advance model index (for testing rotation)
  static void advanceRotationForTesting() {
    final cascade = AppConfig.geminiModelRotationCascade;
    _currentModelIndex = (_currentModelIndex + 1) % cascade.length;
    _lastRotationDate = DateTime.now();
  }

  /// Checks if a new day has arrived. If yes, resets back to the top model (sembase-2.5-flash-lite).
  static int _getEffectiveModelIndex() {
    final now = DateTime.now();
    if (_lastRotationDate == null) {
      _lastRotationDate = now;
      return _currentModelIndex;
    }
    // Check if midnight has crossed or 24 hours have elapsed
    if (now.day != _lastRotationDate!.day || now.difference(_lastRotationDate!).inHours >= 24) {
      _currentModelIndex = 0;
      _lastRotationDate = now;
      AppLogService.info(
        AppLogService.catAction,
        'Daily quota reset detected. Resetting SemBase AI model rotation cascade to: ${toPublicModelName(AppConfig.geminiModelRotationCascade.first)}',
      );
    }
    return _currentModelIndex.clamp(0, AppConfig.geminiModelRotationCascade.length - 1);
  }

  /// Helper to check if an error represents a 429 quota exhaustion or rate limit
  static bool isQuotaOrRateLimitError(dynamic error) {
    if (error == null) return false;
    final str = error.toString().toLowerCase();
    return str.contains('429') ||
        str.contains('resource_exhausted') ||
        str.contains('quota') ||
        str.contains('rate limit') ||
        str.contains('rate-limits') ||
        str.contains('generaterequestsperday');
  }

  /// Helper to check if an error represents an unavailable / retired model ID (404)
  static bool isModelNotFoundError(dynamic error) {
    if (error == null) return false;
    final str = error.toString().toLowerCase();
    return str.contains('404') ||
        str.contains('not_found') ||
        str.contains('model not found') ||
        str.contains('is not found');
  }

  /// Helper to check if an error is a pure network connectivity failure
  static bool isNetworkOrSocketError(dynamic error) {
    if (error == null) return false;
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('connection refused') ||
        str.contains('connection closed');
  }

  /// Extracts retry delay in milliseconds from AI rate limit errors (with safety jitter)
  static int? extractRetryDelayMs(dynamic error) {
    if (error == null) return null;
    final raw = error.toString();
    final secMatch = RegExp(r'retry(?:Delay|\s+in)\D*(\d+(?:\.\d+)?)\s*s', caseSensitive: false).firstMatch(raw);
    if (secMatch != null) {
      final seconds = double.tryParse(secMatch.group(1) ?? '');
      if (seconds != null) {
        return ((seconds * 1000).toInt() + 300).clamp(500, 5000);
      }
    }
    if (raw.contains('429') || raw.contains('RESOURCE_EXHAUSTED')) {
      return 2500;
    }
    return null;
  }

  /// Extracts structured schedule data from raw document text using SemBase AI
  /// Automatically cascades across all free-tier model buckets on 429 rate limit / quota exhaustion.
  static Future<ParsedCorData> extractWithGemini(String rawText) async {
    if (rawText.trim().isEmpty) {
      throw const FormatException('Document text is empty.');
    }

    final cascade = AppConfig.geminiModelRotationCascade;
    final startIndex = _getEffectiveModelIndex();
    dynamic lastError;

    AppLogService.info(
      AppLogService.catAction,
      'Initiating SemBase AI schedule extraction with multi-model quota rotation',
      details: 'Input length: ${rawText.length} chars | Starting model: ${toPublicModelName(cascade[startIndex])}',
    );

    for (int i = 0; i < cascade.length; i++) {
      final modelIndex = (startIndex + i) % cascade.length;
      final modelName = cascade[modelIndex];
      final publicModelName = toPublicModelName(modelName);

      AppLogService.info(
        AppLogService.catAction,
        'Attempting AI Extraction with [$publicModelName] (Bucket ${modelIndex + 1}/${cascade.length})',
      );

      try {
        final parsed = await _attemptExtractionWithModel(rawText, modelName);
        if (parsed != null && parsed.courses.isNotEmpty) {
          // Success! Save modelIndex for subsequent extractions today
          _currentModelIndex = modelIndex;
          _lastRotationDate = DateTime.now();
          AppLogService.success(
            AppLogService.catAction,
            'Successfully extracted schedule using model [$publicModelName]',
            details: 'Courses: ${parsed.courses.length}, Total Units: ${parsed.totalUnits}',
          );
          return parsed;
        }
      } catch (err) {
        lastError = err;

        if (isNetworkOrSocketError(err)) {
          throw const SocketException(
            'Unable to reach SemBase AI service. Please check your internet connection and try again.',
          );
        }

        if (isQuotaOrRateLimitError(err)) {
          AppLogService.warning(
            AppLogService.catSync,
            'Free quota reached for model [$publicModelName] (429/Resource Exhausted). Rotating to next model bucket...',
            details: '$err',
          );
          _currentModelIndex = (modelIndex + 1) % cascade.length;
          _lastRotationDate = DateTime.now();
          continue;
        }

        if (isModelNotFoundError(err)) {
          AppLogService.warning(
            AppLogService.catSync,
            'Model [$publicModelName] not available on provider (404). Rotating to next model...',
          );
          _currentModelIndex = (modelIndex + 1) % cascade.length;
          _lastRotationDate = DateTime.now();
          continue;
        }

        AppLogService.error(
          AppLogService.catSync,
          'Extraction issue on [$publicModelName]: $err. Rotating to next model...',
        );
        _currentModelIndex = (modelIndex + 1) % cascade.length;
        _lastRotationDate = DateTime.now();
      }
    }

    if (lastError != null) {
      throw Exception(sanitizeUserErrorMessage(lastError));
    }

    throw const SocketException(
      'Unable to reach SemBase AI service. Please check your internet connection and try again.',
    );
  }

  static Future<ParsedCorData?> _attemptExtractionWithModel(String rawText, String modelName) async {
    final publicModelName = toPublicModelName(modelName);

    // 429 Shield: Max 2 attempts on the same model (1 initial + 1 sleep retry if transient burst)
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        // 1. Try Supabase Edge Function Proxy
        if (!AppConfig.supabaseUrl.contains('your-project')) {
          final client = Supabase.instance.client;
          final response = await client.functions
              .invoke(
                AppConfig.geminiFunctionEndpoint,
                headers: {
                  'apikey': AppConfig.supabaseAnonKey,
                  'Authorization': 'Bearer ${client.auth.currentSession?.accessToken ?? AppConfig.supabaseAnonKey}',
                },
                body: {
                  'text': rawText,
                  'prompt': _systemPrompt,
                  'model': modelName,
                },
              )
              .timeout(const Duration(seconds: 35));

          if (response.status == 200 && response.data != null) {
            final parsed = parseGeminiJson(response.data);
            if (parsed.courses.isNotEmpty) {
              return parsed;
            }
          } else {
            final errorData = response.data?.toString() ?? 'status ${response.status}';
            throw Exception('Edge Function Error ($publicModelName): $errorData');
          }
        }
      } catch (e) {
        // Check if direct API key is configured
        final apiKey = AppConfig.geminiApiKey;
        if (apiKey.isNotEmpty) {
          try {
            final parsed = await _callDirectGeminiApi(rawText, apiKey, modelName: modelName);
            if (parsed.courses.isNotEmpty) {
              return parsed;
            }
          } catch (directErr) {
            if (isQuotaOrRateLimitError(directErr) && attempt == 0) {
              final delayMs = extractRetryDelayMs(directErr);
              if (delayMs != null && delayMs <= 4000) {
                AppLogService.info(
                  AppLogService.catSync,
                  'Transient rate limit burst detected for [$publicModelName]. 429 Shield sleeping ${delayMs}ms before retry...',
                );
                await Future.delayed(Duration(milliseconds: delayMs));
                continue;
              }
            }
            rethrow;
          }
        }

        // 429 Error Shield: Check if it's a short burst rate limit with retryDelay
        if (isQuotaOrRateLimitError(e) && attempt == 0) {
          final delayMs = extractRetryDelayMs(e);
          final isDailyExhausted = e.toString().contains('GenerateRequestsPerDay') ||
              e.toString().contains('Daily limit') ||
              e.toString().contains('free_tier_requests');
          if (delayMs != null && delayMs <= 4500 && !isDailyExhausted) {
            AppLogService.info(
              AppLogService.catSync,
              'Transient rate limit burst on [$publicModelName]. 429 Shield sleeping ${delayMs}ms before retry...',
            );
            await Future.delayed(Duration(milliseconds: delayMs));
            continue; // Retry once
          }
        }

        rethrow;
      }
    }
    return null;
  }

  /// Returns a clean, user-safe error message without exposing backend API links or internal stack traces
  static String sanitizeUserErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';
    final raw = error.toString();

    // 1. Check for specific known conditions
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('timed out') ||
        raw.contains('TimeoutException') ||
        raw.contains('Network is unreachable') ||
        raw.contains('ClientException') ||
        raw.contains('Connection refused')) {
      return 'Unable to reach SemBase AI. Please check your internet connection and try again.';
    }

    if (raw.contains('429') ||
        raw.contains('RESOURCE_EXHAUSTED') ||
        raw.contains('Quota exceeded') ||
        raw.contains('quota') ||
        raw.contains('rate limit')) {
      return 'All cloud AI free quota buckets are currently exhausted for today. Please use the Offline Parser or try again tomorrow.';
    }

    if (raw.contains('502') || raw.contains('Bad Gateway')) {
      return 'SemBase AI service is temporarily busy. Please retry in a few seconds.';
    }

    if (raw.contains('404') || raw.contains('NOT_FOUND')) {
      return 'SemBase AI model is currently updating. Please try again shortly.';
    }

    if (raw.contains('401') || raw.contains('403') || raw.contains('Unauthorized')) {
      return 'Cloud service session expired. Please sign in again.';
    }

    if (raw.contains('0 courses') || raw.contains('unrecognized') || raw.contains('timetable slots')) {
      return 'SemBase AI was unable to detect course timetable slots from this document text.';
    }

    // 2. Strip any URL links, domains, or Supabase project paths
    String cleaned = raw
        .replaceAll(RegExp(r'https?:\/\/[^\s\)\],]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'([a-zA-Z0-9_-]+\.supabase\.co[^\s\)\],]*)', caseSensitive: false), '')
        .replaceAll(RegExp(r'Endpoint:\s*\S+', caseSensitive: false), '')
        .replaceAll(RegExp(r'details:\s*\{.*?\}', dotAll: true), '')
        .replaceAll(RegExp(r'^[a-zA-Z0-9_]*Exception:\s*'), '')
        .replaceAll('FunctionException', 'Service Error')
        .replaceAll('lya(', '')
        .replaceAll(')', '')
        .replaceAllMapped(RegExp(r'gemini-\d+(\.\d+)?-flash(-lite|-preview)?', caseSensitive: false), (m) => m.group(0)!.replaceAll(RegExp(r'gemini-', caseSensitive: false), 'sembase-'))
        .replaceAll('Gemini AI', 'SemBase AI')
        .replaceAll('Gemini', 'SemBase AI')
        .trim();

    if (cleaned.isEmpty || cleaned.length < 5 || cleaned == 'null') {
      return 'Could not extract schedule with SemBase AI. Please try again or paste schedule text directly.';
    }

    return cleaned;
  }

  static Future<ParsedCorData> _callDirectGeminiApi(
    String rawText,
    String apiKey, {
    required String modelName,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    final url = Uri.parse(
      '${AppConfig.geminiDirectApiEndpoint}/$modelName:generateContent?key=$apiKey',
    );

    final requestPayload = {
      'contents': [
        {
          'parts': [
            {'text': '$_systemPrompt\n\nDocument Text to Parse:\n"""\n$rawText\n"""'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      }
    };

    try {
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(requestPayload));

      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final jsonStr = parts[0]['text'] as String? ?? '{}';
            return parseGeminiJson(jsonStr);
          }
        }
      } else {
        throw Exception('Gemini API status ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }

    throw const FormatException('Failed to receive structured schedule from Gemini AI.');
  }

  /// Cleans markdown syntax like ```json ... ``` and extracts pure JSON string
  static String sanitizeJsonString(String raw) {
    var text = raw.trim();

    // 1. Extract content from markdown code fences if present
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false).firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    }

    // 2. Slice from first '{' to last '}' to strip any surrounding conversational preamble
    final startIdx = text.indexOf('{');
    final endIdx = text.lastIndexOf('}');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      text = text.substring(startIdx, endIdx + 1);
    } else {
      // Check for array format [ ... ]
      final startArr = text.indexOf('[');
      final endArr = text.lastIndexOf(']');
      if (startArr != -1 && endArr != -1 && endArr > startArr) {
        text = text.substring(startArr, endArr + 1);
      }
    }

    return text.trim();
  }

  /// Converts sanitized Gemini JSON map into standard ParsedCorData model
  static ParsedCorData parseGeminiJson(dynamic rawData) {
    if (rawData == null) {
      return ParsedCorData.empty();
    }

    Map<String, dynamic> json;
    if (rawData is String) {
      final clean = sanitizeJsonString(rawData);
      try {
        final decoded = jsonDecode(clean);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else if (decoded is List) {
          json = {'courses': decoded};
        } else {
          json = {};
        }
      } catch (_) {
        json = {};
      }
    } else if (rawData is Map<String, dynamic>) {
      json = rawData;
    } else if (rawData is List) {
      json = {'courses': rawData};
    } else {
      json = {};
    }

    // 1. Unwrap raw Gemini API candidates if the Edge function forwarded the raw Gemini payload
    if (json.containsKey('candidates')) {
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String? ?? '{}';
          return parseGeminiJson(text);
        }
      }
    }

    // 2. Unwrap potential nested wrappers (e.g. { "data": { ... } } or { "schedule": { ... } })
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      json = json['data'] as Map<String, dynamic>;
    } else if (json.containsKey('schedule') && json['schedule'] is Map<String, dynamic>) {
      json = json['schedule'] as Map<String, dynamic>;
    } else if (json.containsKey('result') && json['result'] is Map<String, dynamic>) {
      json = json['result'] as Map<String, dynamic>;
    }

    final studentNo = (json['studentNo'] ?? json['student_no'] ?? json['studentId'] ?? json['student_id'] ?? '').toString();
    final section = (json['section'] ?? json['course_section'] ?? json['courseSection'] ?? '').toString();
    final schoolYear = (json['schoolYear'] ?? json['school_year'] ?? json['academic_year'] ?? json['academicYear'] ?? '').toString();
    final semester = (json['semester'] ?? json['term'] ?? '').toString();
    final totalUnitsRaw = json['totalUnits'] ?? json['total_units'] ?? json['units'];
    final double totalUnits = (totalUnitsRaw is num) ? totalUnitsRaw.toDouble() : 0.0;

    final coursesRaw = json['courses'] ?? json['subjects'] ?? json['classes'] ?? json['enrolled_courses'] ?? json['course_list'] ?? [];
    final List<ParsedCourse> parsedCourses = [];

    if (coursesRaw is List) {
      for (final c in coursesRaw) {
        if (c is! Map<String, dynamic>) continue;

        final courseCode = (c['courseCode'] ?? c['course_code'] ?? c['code'] ?? c['subject_code'] ?? c['subjectCode'] ?? '').toString().trim();
        final courseTitle = (c['courseTitle'] ?? c['course_title'] ?? c['title'] ?? c['description'] ?? c['name'] ?? courseCode).toString().trim();
        final instructorRaw = (c['instructor'] ?? c['instructorName'] ?? c['instructor_name'] ?? c['professor'] ?? c['profName'] ?? c['prof_name'] ?? c['faculty'] ?? c['teacher'] ?? '').toString().trim();
        final String? instructorName = (instructorRaw.isNotEmpty && instructorRaw.toUpperCase() != 'TBA') ? instructorRaw : null;
        final lecRaw = c['lecUnits'] ?? c['lec_units'] ?? c['lecture_units'];
        final double lecUnits = (lecRaw is num) ? lecRaw.toDouble() : 0.0;
        final labRaw = c['labUnits'] ?? c['lab_units'] ?? c['laboratory_units'];
        final double labUnits = (labRaw is num) ? labRaw.toDouble() : 0.0;

        final schedulesRaw = c['schedules'] ?? c['schedule'] ?? c['slots'] ?? c['times'] ?? [];
        final List<ParsedSchedule> schedules = [];

        if (schedulesRaw is List) {
          for (final s in schedulesRaw) {
            if (s is! Map<String, dynamic>) continue;

            var dayToken = (s['dayToken'] ?? s['day_token'] ?? s['day'] ?? s['days'] ?? 'M').toString().trim().toUpperCase();
            if (!['M', 'T', 'W', 'TH', 'F', 'S'].contains(dayToken)) {
              if (dayToken.startsWith('TH')) {
                dayToken = 'TH';
              } else if (dayToken.startsWith('TU')) {
                dayToken = 'T';
              } else if (dayToken.startsWith('M')) {
                dayToken = 'M';
              } else if (dayToken.startsWith('W')) {
                dayToken = 'W';
              } else if (dayToken.startsWith('F')) {
                dayToken = 'F';
              } else if (dayToken.startsWith('S')) {
                dayToken = 'S';
              } else {
                dayToken = 'M';
              }
            }

            int startMinutes = 420;
            final startRaw = s['startMinutes'] ?? s['start_minutes'] ?? s['startTime'] ?? s['start_time'] ?? s['start'];
            if (startRaw is num) {
              startMinutes = startRaw.toInt();
            } else if (startRaw is String) {
              startMinutes = TimeFormatter.parseTimeToMinutes(startRaw);
            }

            int endMinutes = 540;
            final endRaw = s['endMinutes'] ?? s['end_minutes'] ?? s['endTime'] ?? s['end_time'] ?? s['end'];
            if (endRaw is num) {
              endMinutes = endRaw.toInt();
            } else if (endRaw is String) {
              endMinutes = TimeFormatter.parseTimeToMinutes(endRaw);
            }

            final roomCode = (s['roomCode'] ?? s['room_code'] ?? s['room'] ?? s['location'] ?? 'TBA').toString().trim();
            final sessionType = (s['sessionType'] ?? s['session_type'] ?? s['type'] ?? 'lecture').toString().toLowerCase().contains('lab') ? 'lab' : 'lecture';
            final isTba = (s['isTba'] ?? s['is_tba'] as bool?) ?? (roomCode.isEmpty || roomCode.toUpperCase() == 'TBA');

            schedules.add(ParsedSchedule(
              dayToken: dayToken.isNotEmpty ? dayToken : 'M',
              startMinutes: startMinutes,
              endMinutes: endMinutes > startMinutes ? endMinutes : startMinutes + 60,
              roomCode: roomCode.isNotEmpty ? roomCode : 'TBA',
              sessionType: sessionType,
              isTba: isTba,
            ));
          }
        }

        if (courseCode.isNotEmpty || courseTitle.isNotEmpty) {
          parsedCourses.add(ParsedCourse(
            courseCode: courseCode.isNotEmpty ? courseCode : courseTitle,
            courseTitle: courseTitle.isNotEmpty ? courseTitle : courseCode,
            lecUnits: lecUnits,
            labUnits: labUnits,
            instructorName: instructorName,
            schedules: schedules.isNotEmpty
                ? schedules
                : [
                    ParsedSchedule(
                      dayToken: 'M',
                      startMinutes: 420,
                      endMinutes: 540,
                      roomCode: 'TBA',
                      sessionType: 'lecture',
                      isTba: true,
                    ),
                  ],
          ));
        }
      }
    }

    final computedTotalUnits = totalUnits > 0
        ? totalUnits
        : parsedCourses.fold<double>(0.0, (sum, c) => sum + c.totalUnits);

    return ParsedCorData(
      studentNo: studentNo,
      section: section,
      schoolYear: schoolYear,
      semester: semester,
      totalUnits: computedTotalUnits,
      courses: parsedCourses,
    );
  }
}
