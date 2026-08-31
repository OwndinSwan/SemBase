<div align="center">

# 🎓 SemBase
**Modern, Offline-First Academic Timetable, Task Vault & Cloud Synchronizer for Students**

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Drift%202.24-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud%20Vault-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Gemini AI](https://img.shields.io/badge/AI%20Engine-Gemini%20Rotation-8E75FF?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)
[![Android](https://img.shields.io/badge/Android-SDK%2026--36-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/OwndinSwan/SemBase/releases)
[![Tests](https://img.shields.io/badge/Tests-51%20Passing-brightgreen?style=for-the-badge&logo=flutter)](test/)
[![Version](https://img.shields.io/badge/Version-v1.0.8%2B9-blue?style=for-the-badge)](pubspec.yaml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-key-features">Key Features</a> •
  <a href="#-architecture--tech-stack">Architecture</a> •
  <a href="#-project-structure">Project Structure</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-automated-test-suite">Test Suite</a> •
  <a href="#-building-release-apks">Building APKs</a> •
  <a href="#-github-auto-update">Auto-Update</a> •
  <a href="#-companion-utilities">Utilities</a>
</p>

</div>

---

## 📖 Overview

**SemBase** is an advanced, standalone Android application built with **Flutter 3.29+** and **Dart 3.7+**, engineered specifically for university and college students. It unifies **zero-latency local-first storage (Drift SQLite)** with **transactional cloud synchronization (Supabase)**, automated Certificate of Registration (COR) PDF ingestion with isolate parsing and a multi-model **Gemini Cloud AI quota rotation cascade**, interactive weekly timetable grid with pinch-to-zoom and side-by-side collision handling, exact native class alarms, smart vacant break calculation, personal JSON backup & timestamp-aware smart merge, RFC 5545 `.ics` calendar export, and a Pro voucher activation engine.

---

## ✨ Key Features

### ⚡ 1. Local-First & Zero-Latency Performance
- **100% Offline Capability**: All academic profiles, courses, schedule slots, syllabus tasks, prof metadata, and diagnostic logs are persisted locally in an optimized Drift SQLite database.
- **Instant Response (<10ms)**: Adding tasks, shifting deadlines, toggling checklist items, or switching screens occurs with zero UI blocking or network dependencies.
- **Reactive Stream Architecture**: UI components bind directly to Drift reactive stream providers (`watchCourses()`, `watchPendingCount()`, `watchActiveProfile()`, etc.).

### 🤖 2. Dual Ingestion: Local Isolate COR Parser & Gemini Cloud AI Rotation Cascade
- **Background Isolate PDF Parsing**: Fast on-device document extraction powered by `syncfusion_flutter_pdf` in a dedicated background isolate (`cor_isolate.dart`).
- **Universal Academic Regex Matcher (`CorMatcher`)**: Extracts Student Number, Section (e.g., *BSCS 3-1, BSIT-2A*), Academic Year, Semester, Subject Codes, Titles, Split Days (*M/TH, T/F, W/S, TTH, MW*), Class Timestamps (*12-hr AM/PM and 24-hr military*), Split Rooms (*CL1/RM.5*), and TBA slots.
- **Cloud AI (Gemini) Fallback & Rotation Cascade (`GeminiCorParserService`)**: For complex, irregular, or unstandardized academic documents, SemBase routes extraction to Cloud AI with an automated quota rotation cascade across multiple free-tier model buckets (`sembase-2.5-flash-lite`, `sembase-3.1-flash-lite`, `sembase-3.5-flash-lite`, `sembase-2.5-flash`, `sembase-3.5-flash`, `sembase-3.6-flash`, `sembase-3.7-flash`, `sembase-3-flash-preview`).
- **Quota Error Sanitization & Delay Extraction**: Automatically captures rate limits (`429 / RESOURCE_EXHAUSTED`), extracts server `retryDelay`, cycles smoothly to the next model tier, and presents clean user-facing status banners.
- **Supabase Edge Function Architecture**: Production calls route securely through the `parse-cor` Supabase Edge Function with direct Google Generative AI API fallback.

### 🔄 3. Transactional Cloud Sync & Outbox Queue
- **Transactional FIFO Outbox (`sync_queue`)**: All local mutations (INSERT, UPDATE, DELETE) are recorded in an atomic SQLite outbox and dispatched automatically upon network reconnection.
- **Cross-Device Real-Time Sync**: Synchronizes schedule and task updates between devices in **<500ms** via Supabase Realtime WebSockets.
- **Last-Write-Wins (LWW) Conflict Resolution**: Protects against data overwrite collisions during simultaneous multi-device offline operations.
- **Multi-Account Switching Safety**: Detects account changes on shared devices and prevents data pollution by offering fresh cloud pull or local adoption.
- **Live Connectivity Status Badge**: Displays real-time cloud connection health across all screens.

### 🔍 4. Granular Visual Sync Diff Engine (`SyncDiffService`)
- **Granular Visual Diff Preview**: Compares incoming COR schedules with the active database, clearly highlighting added, modified, unchanged, and dropped courses.
- **Smart Task & Notes Preservation**: Automatically preserves existing course syllabus tasks, deadlines, and instructor LMS metadata when updating or re-importing an existing semester schedule.
- **Academic History Archival**: Cleanly archives previous semester courses for future reference in the Archive Explorer without cluttering active schedules.

### 📅 5. Interactive Weekly Timetable Grid & Daily Timeline
- **Pinch-to-Zoom & Pan Schedule Grid**: Interactive 6-day timetable with smooth multi-touch scaling, auto-hiding zoom buttons, bottom-safe navigation insets, and high-contrast color coding.
- **Side-by-Side Overlap Clustering**: Renders overlapping or simultaneous class schedules side-by-side with proportional column widths to prevent visual clipping.
- **Live Class Countdown Hero**: Real-time progress bar (updated every second) calculating exact time remaining for active classes and showing up-next subjects with room locator.
- **Urgent Tasks Card**: Proactively surfaces upcoming academic deadlines within a 48-hour window with instant completion toggles and one-tap +/- 1-week deadline shifters.
- **Morning Briefing Banner**: Daily schedule overview highlighting start time, total class load, and finish time.

### ☕ 6. Smart Vacant Period Engine
- **Mathematical Interval-Merge Algorithm**: Computes vacant periods across all active days (`M` through `S`), merging multi-section classes into continuous spans with zero false gaps.
- **Interactive Vacant Customization**: Tap any vacant block to assign custom activity labels (*Lunch Break, Study Session, Library Time, Gym / Workout, Org Meeting*), modify time windows, or hide/delete vacant blocks.

### 🔔 7. Standalone Class Alarms & Morning Schedule Digest
- **Exact Native Android Alarms**: Configured via `android_alarm_manager_plus` and `flutter_local_notifications` with customizable lead times (5, 10, 15, 30, 45, or 60 minutes).
- **Daily 7:00 AM Morning Briefing**: Sends a daily digest notification summarizing the day's class timeline and due assignments.
- **Battery Optimization & Doze Resistant**: Native exact alarms trigger reliably without relying on third-party calendar sync.

### 💎 8. Pro Subscription & Cloud Voucher Activation System
- **Tier Architecture**: Offers Free Academic and Pro tiers (Monthly, Semester Pass, Lifetime Degree).
- **Online Cloud Voucher Redemption**: 16-character activation code redemption backed by Supabase `subscription_keys` and `user_subscriptions` tables.
- **Hardware-Encrypted Secure Storage**: Encrypts and caches activation credentials using `flutter_secure_storage` with Android KeyStore integration.
- **Admin Voucher Key Generator**: Companion standalone HTML utility ([`admin_key_generator.html`](admin_key_generator.html)) for generating and managing voucher activation keys in Supabase.
- **Live Admin Modification Sync**: Dynamically syncs changes to subscription duration, expiry dates, or active status directly from the cloud database.

### 📦 9. Personal JSON Backup & Restore Engine
- **Full Database Export**: Serializes all academic profiles, courses, schedules, syllabus tasks, and instructor metadata into a structured `.json` backup file.
- **System Share Sheet Integration**: Direct export via Android native share sheet (`share_plus`).
- **Validation & Smart Merge / Clean Overwrite**: Validates backup schema integrity and supports either clean overwrite or timestamp-aware smart merging (preserves newer local task completions when importing older backups).

### 📆 10. RFC 5545 iCalendar (`.ics`) & Plaintext Timetable Export
- **RFC 5545 `.ics` Export**: Export your complete semester timetable into standardized `.ics` calendar files compatible with Google Calendar, Apple Calendar, and Microsoft Outlook.
- **Plaintext Timetable Sharing**: Formats and copies a clean, human-readable class schedule to the clipboard for instant messaging and social sharing.

### 🔒 11. Security, Biometrics & Danger Zone
- **Biometric App Lock**: Fingerprint, Face ID, and Device PIN/Pattern fallback via `local_auth`.
- **Authentication Flexibility**: Email/Password authentication, Google OAuth 2.0, or full Offline Guest Mode.
- **Danger Zone Utilities**: Force cache re-indexing, local database reset, and cloud account deletion with animated confirmation modals.

### 📋 12. Diagnostic Activity Logging (`AppLogService`)
- **Comprehensive Audit Trail**: In-memory ring buffer and persistent logging across categories (`ACTION`, `SYNC`, `ALARM`, `DATABASE`, `AUTH`, `SYSTEM`).
- **In-App Activity Logs Viewer**: Searchable, filterable audit log viewer with real-time category chips, clear log options, and one-tap clipboard/export functionality.

### 🚀 13. GitHub Releases Auto-Update Engine
- **Direct GitHub API Integration**: Checks `OwndinSwan/SemBase` releases against the installed semantic version (`1.0.8+9`).
- **In-App Update Modal**: Displays markdown release notes and provides direct download and installation gates for the latest APK.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── backup/            # LocalBackupService (JSON export, schema validation, Smart Merge)
│   ├── config/            # Centralized Configuration Manifest (AppConfig)
│   ├── database/          # Drift SQLite ORM, Tables, Foreign Keys & Migrations
│   │   └── connection/    # Native SQLite Driver Connection
│   ├── logging/           # AppLogService (Audit trail daemon & in-memory ring buffer)
│   ├── notifications/     # Exact Class Alarms & Daily Morning Briefing Daemon
│   ├── providers/         # Global Riverpod Singletons (DB, Sync, Subscriptions)
│   ├── services/          # AppUpdateService, SubscriptionService, VacantService
│   ├── sync/              # Transactional Outbox Worker & Supabase Cloud Sync Engine
│   └── utils/             # Time Formatter, RFC 5545 ICS Calendar Exporter
├── features/
│   ├── archive/           # Academic Term Explorer & Semester History
│   ├── auth/              # Email Auth, Google OAuth 2.0, Keystore & Guest Mode
│   ├── cor_parser/        # Isolate PDF Parser, Regex Matcher & Gemini AI Fallback
│   │   ├── models/        # Parsed COR Models & Extraction Schemas
│   │   ├── services/      # CorMatcher, CorIsolate, GeminiCorParserService
│   │   └── widgets/       # COR Ingestion Dialogs & AI Status Banners
│   ├── dashboard/         # Live Hero Countdown, Urgent Tasks, Daily Timeline
│   ├── schedule_grid/     # Weekly 6-Day Grid Timetable, Pinch-to-Zoom & Overlap Layout
│   ├── settings/          # Settings Dashboard & Sub-Screens
│   │   └── sub_screens/   # Pro Plans, Cloud Sync, Backup, Logs, Security, Danger Zone
│   ├── subject_hub/       # Subject Details, Tasks, Notes, LMS Links, ICS Export
│   ├── sync_diff/         # COR Sync Diff Matcher, Diff Models & Review Dialog
│   └── update/            # In-App Update Modal & Download Gate
└── shared/
    ├── theme/             # Modern Dark Glassmorphic Theme System (AppTheme)
    └── widgets/           # Status Badges, Pro Badges, Animated Dialogs, Glass Cards
```

### Core Technologies:
- **Framework**: [Flutter](https://flutter.dev) (v3.29+) / [Dart](https://dart.dev) (v3.7+)
- **State Management**: [Riverpod](https://riverpod.dev) (v2.6.1)
- **Local Database**: [Drift (SQLite)](https://drift.simonbinder.eu) (v2.24.0) with `sqlite3_flutter_libs`
- **Cloud Backend**: [Supabase Flutter](https://supabase.com/docs/reference/dart/start) (v2.8.4)
- **AI Document Extraction**: Google Gemini Cloud AI via Supabase Edge Functions with multi-model quota rotation
- **PDF Engine**: [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf) (v28.2.3)
- **Alarms & Notifications**: `android_alarm_manager_plus` (v4.0.7) & `flutter_local_notifications` (v18.0.1)
- **Biometrics & Keystore**: `local_auth` (v2.3.0) & `flutter_secure_storage` (v9.2.2)
- **File Sharing & Utilities**: `share_plus` (v10.1.3), `file_picker` (v8.1.7), `url_launcher` (v6.3.1)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.29.0`)
- [Android Studio](https://developer.android.com/studio) / Android SDK (`API Level 26+`, Target `35`, Compile `36`)
- Java JDK 17+

### 1. Clone the Repository
```bash
git clone https://github.com/OwndinSwan/SemBase.git
cd SemBase
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Database Code (Drift)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run Locally
```bash
flutter run
```

---

## 🧪 Automated Test Suite

SemBase includes a comprehensive suite of **51 unit and integration tests** covering all critical business logic:

```bash
flutter test
```

### Test Coverage (10 Test Suites • 51 Passing):
- **`cor_matcher_test.dart`**: Multi-format COR parsing, split days (*M/TH, T/F, W/S, TTH, MW*), military/12h times, room codes, TBA slots.
- **`gemini_cor_parser_test.dart`**: Multi-model quota rotation cascade, 429 / `RESOURCE_EXHAUSTED` rate limit detection, `retryDelay` parsing, branded error sanitization (`sembase-`), and daily midnight reset logic.
- **`local_backup_test.dart`**: JSON serialization, schema validation, clean overwrite, and timestamp-aware Smart Merge (preserves newer local task states).
- **`cloud_sync_test.dart`**: Outbox mutation queue insertion, FIFO draining, and Last-Write-Wins payload handling.
- **`subscription_service_test.dart`**: Pro plan resolution, expiry evaluation, voucher format verification, and days remaining logic.
- **`task_deadline_test.dart`**: Task checklist state transitions, +/- 1-week deadline shifting, 48-hr urgent query filtering, and task details preservation.
- **`time_formatter_test.dart`**: 12h/24h conversion, time ranges, day token mapping, and cross-timezone due date normalization.
- **`ics_generator_test.dart`**: RFC 5545 calendar file generation, recurrence rules, and formatted plaintext timetable output.
- **`app_log_service_test.dart`**: Audit log recording, category filtering, in-memory buffering, and log export formatting.
- **`app_update_test.dart`**: Semantic version comparison and GitHub OTA update detection.

---

## 📦 Building Release APKs

For detailed environment configuration, Android SDK locking, and troubleshooting, consult [BUILD_GUIDE.md](BUILD_GUIDE.md) and [FLUTTER_ANDROID_UNIVERSAL_BUILD_GUIDE.md](FLUTTER_ANDROID_UNIVERSAL_BUILD_GUIDE.md).

### Split-ABI Release (Recommended for Distribution):
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./build/symbols
```

#### Generated Binaries:
- **`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`** *(Modern 64-bit Android Devices — ~22.2 MB)*
- **`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`** *(32-bit Legacy Android Devices — ~19.8 MB)*
- **`build/app/outputs/flutter-apk/app-x86_64-release.apk`** *(Emulators & x86_64 Devices — ~23.7 MB)*

### Universal Fat APK (All Architectures in One File):
```bash
flutter build apk --release --no-split-per-abi --obfuscate --split-debug-info=./build/symbols
```

---

## 🔄 GitHub Auto-Update Workflow

SemBase automatically detects new releases published on GitHub:

1. Update `version` in [`pubspec.yaml`](pubspec.yaml) and `AppConfig.appVersion` in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart) (e.g., `1.0.8+9`).
2. Build release APK (`app-arm64-v8a-release.apk`).
3. Navigate to [GitHub Releases > Draft a New Release](https://github.com/OwndinSwan/SemBase/releases/new).
4. Set the tag to match your new version (e.g., **`v1.0.8`**).
5. Attach `app-arm64-v8a-release.apk` to the release assets and click **Publish Release**.
6. Installed SemBase apps will automatically detect the new release and present the in-app update banner.

---

## 🛠️ Companion Utilities

- **[`admin_key_generator.html`](admin_key_generator.html)**: Standalone web portal for administrators to generate, manage, and directly register 16-character Pro voucher keys in Supabase.
- **[`supabase_subscription_schema.sql`](supabase_subscription_schema.sql)**: Complete PostgreSQL database schema, RLS security policies, and indexes for `subscription_keys` and `user_subscriptions`.
- **[`backup_project.bat`](backup_project.bat)** / **[`restore_project.bat`](restore_project.bat)** / **[`create_backup.ps1`](create_backup.ps1)**: Automated backup and restoration scripts for source code and asset preservation.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ for students everywhere.</sub>
</div>
