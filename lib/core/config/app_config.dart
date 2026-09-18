import 'dart:core';

/// Centralized Configuration Manifest (Single-File Mandate)
/// All environmental parameters, OAuth client IDs, Supabase endpoints,
/// alarm timings, and parser rules are centralized here.
class AppConfig {
  static const String appName = "SemBase";
  static const String appVersion = "1.0.10+2027";

  // 1. SUPABASE CLOUD SYNC CONFIGURATION
  static const String supabaseUrl = "https://szxoxcyztowtgvrpjibx.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6eG94Y3l6dG93dGd2cnBqaWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3OTczNDUsImV4cCI6MjEwMzM3MzM0NX0.1qX1LwDIyP4iyDk-wMIb-7yv5RabqW_TnkjKUE_DTiM";

  // 2. GOOGLE OAUTH 2.0 CREDENTIALS
  static const String googleWebClientId =
      "1029955514037-uuqtvb2klregtb2tg7k5n0tvrhal7sd5.apps.googleusercontent.com";
  static const String googleAndroidClientId =
      "1029955514037-s0shp3pfqk0mj3157q2f3j29mbsl6qpj.apps.googleusercontent.com";

  // 3. LOCAL DRIFT SQLITE DATABASE CONFIGURATION
  static const String driftDbName = "sembase_local_vault.sqlite";
  static const int driftDbSchemaVersion = 2;

  // 4. ALARM & NOTIFICATION PARAMETERS
  static const Duration preClassAlarmOffset = Duration(minutes: 15);
  static const int deadlineAlertWindowHours = 48;
  static const bool enableMorningScheduleBriefing = true;
  static const int morningBriefingHour = 7;
  static const int morningBriefingMinute = 0;

  // 5. PARSER & SCHEDULING RULE CONSTANTS
  static const List<String> dayTokens = ['M', 'T', 'W', 'TH', 'F', 'S'];
  static const Map<String, String> dayNames = {
    'M': 'Monday',
    'T': 'Tuesday',
    'W': 'Wednesday',
    'TH': 'Thursday',
    'F': 'Friday',
    'S': 'Saturday',
  };

  // 6. GITHUB RELEASES & FORCE UPDATE CONFIGURATION
  static const String githubOwner = "OwndinSwan";
  static const String githubRepo = "SemBase";
  static const String githubReleasesApiUrl =
      "https://api.github.com/repos/OwndinSwan/SemBase/releases/latest";
  static const String githubReleasesWebUrl =
      "https://github.com/OwndinSwan/SemBase/releases/latest";
  static const bool isForceUpdateMandatory = false;

  // 7. CLOUD AI (GEMINI) COR EXTRACTION FALLBACK & ROTATION CASCADE
  // Rotation cascade across all free tier model buckets to maximize free requests
  static const List<String> geminiModelRotationCascade = [
    "gemini-2.5-flash-lite",
    "gemini-3.1-flash-lite",
    "gemini-3.5-flash-lite",
    "gemini-2.5-flash",
    "gemini-3.5-flash",
    "gemini-3.6-flash",
    "gemini-3.7-flash",
    "gemini-3-flash-preview",
  ];
  static const String geminiModel = "gemini-2.5-flash-lite"; // Default starting model
  static const String geminiFunctionEndpoint = "parse-cor"; // Supabase Edge Function
  static const String geminiDirectApiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models";
  // Optional direct API key for local development (production uses Supabase Edge Function)
  static const String geminiApiKey = "";
}
