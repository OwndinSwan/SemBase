<div align="center">

# 🎓 SemBase
**Modern, Offline-First Academic Timetable, Task Vault & Cloud Synchronizer for Students**

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Drift%202.24-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud%20Vault-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Android](https://img.shields.io/badge/Android-SDK%2026--36-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/OwndinSwan/SemBase/releases)
[![Tests](https://img.shields.io/badge/Tests-35%20Passing-brightgreen?style=for-the-badge&logo=flutter)](test/)
[![Version](https://img.shields.io/badge/Version-v1.0.7%2B8-blue?style=for-the-badge)](pubspec.yaml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-key-features">Key Features</a> •
  <a href="#-architecture--tech-stack">Architecture</a> •
  <a href="#-project-structure">Project Structure</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-building-release-apks">Building APKs</a> •
  <a href="#-automated-test-suite">Test Suite</a> •
  <a href="#-github-auto-update">Auto-Update</a>
</p>

</div>

---

## 📖 Overview

**SemBase** is a high-performance, standalone Android application built with **Flutter 3.29+** and **Dart 3.7+**, engineered specifically for university and college students. It unifies **zero-latency local-first storage (Drift SQLite)** with **transactional cloud synchronization (Supabase)**, automated Certificate of Registration (COR) PDF ingestion with visual diff merging, exact native alarms, smart vacant break calculation, personal JSON backup & restore, and a Pro voucher activation engine.

---

## ✨ Key Features

### ⚡ 1. Local-First & Zero-Latency Performance
- **100% Offline Capability**: All courses, schedules, syllabus tasks, prof metadata, and activity logs are persisted locally in a Drift SQLite database.
- **Instant Response (<10ms)**: Adding tasks, checking off checklist items, or switching screens occurs with zero UI blocking or network dependencies.
- **Reactive Stream Architecture**: UI components bind directly to Drift reactive stream providers (`watchCourses()`, `watchPendingCount()`, etc.).

### 🔄 2. Transactional Cloud Sync & Outbox Queue
- **Transactional FIFO Outbox (`sync_queue`)**: All local mutations are recorded in an atomic SQLite outbox and dispatched automatically upon network reconnection.
- **Cross-Device Real-Time Sync**: Synchronizes schedule and task updates between devices in **<500ms** via Supabase Realtime WebSockets.
- **Last-Write-Wins (LWW) Conflict Resolution**: Protects against data overwrite collisions during simultaneous multi-device offline operations.
- **Multi-Account Switching Safety**: Detects account changes on shared devices and prevents data pollution by offering fresh cloud pull or local adoption.
- **Live Connectivity Status Badge**: Displays real-time cloud connection health across all screens.

### 📄 3. Intelligent COR Parser & Visual Sync Diff Engine
- **Direct PDF & Raw Text Ingestion**: Background isolate-based document parsing powered by `syncfusion_flutter_pdf`.
- **Pre-configured CvSU & Universal Academic Format Matcher**: Automatically extracts Student Number, Section (e.g., *BSIT-2A*), Academic Year, Semester, Subject Codes, Titles, Split Days (*M/TH, T/F, W/S*), Class Timestamps (*12-hr AM/PM and 24-hr military*), Split Rooms (*CL1/RM.5*), and TBA slots.
- **Granular Visual Diff Preview (`SyncDiffService`)**: Compares incoming COR schedules with the active database, clearly highlighting added, modified, unchanged, and dropped courses.
- **Smart Preservation on Re-import**: Preserves existing course syllabus tasks, deadlines, and instructor LMS metadata when updating an existing semester schedule.
- **Academic History Archival**: Automatically archives previous semester courses for future reference in the Archive Explorer.

### 📅 4. Dynamic Weekly Schedule Grid & Daily Timeline
- **Live Class Countdown Hero**: Real-time progress bar (updated every second) calculating exact time remaining for active classes and showing up-next subjects.
- **Urgent Tasks Card**: Proactively surfaces upcoming academic deadlines within a 48-hour window with quick-toggle completion.
- **Morning Briefing Banner**: Daily schedule overview highlighting start time, total class load, and finish time.
- **6-Day Weekly Schedule Grid**: High-contrast, color-coded timetable layout with bottom-safe insets for gesture navigation.
- **Search & Filter**: Real-time subject filtering by query, pending tasks, or upcoming deadlines.

### ☕ 5. Smart Vacant Period Engine
- **Mathematical Interval-Merge Algorithm**: Computes vacant periods across all active days (`M` through `S`), merging multi-section classes into continuous spans with zero false gaps.
- **Interactive Vacant Customization**: Tap any vacant block to assign custom activity labels (*Lunch Break, Study Session, Library Time, Gym / Workout, Org Meeting*), modify time windows, or hide/delete vacant blocks.

### 🔔 6. Standalone Class Alarms & Morning Schedule Digest
- **Exact Native Android Alarms**: Configured via `android_alarm_manager_plus` and `flutter_local_notifications` with customizable lead times (5, 10, 15, 30, 45, or 60 minutes).
- **Daily 7:00 AM Morning Briefing**: Sends a daily digest notification summarizing the day's class timeline and schedule.
- **Battery Optimization & Doze Resistant**: Native exact alarms trigger reliably without relying on third-party calendar sync.

### 💎 7. Pro Subscription & Cloud Voucher Activation System
- **Tier Architecture**: Offers Free Academic and Pro tiers (Monthly, Semester Pass, Lifetime Degree).
- **Online Cloud Voucher Redemption**: 16-character activation code redemption backed by Supabase `subscription_keys` and `user_subscriptions` tables.
- **Hardware-Encrypted Secure Storage**: Encrypts and caches activation credentials using `flutter_secure_storage` with Android KeyStore integration.
- **Admin Voucher Key Generator**: Companion standalone HTML utility (`admin_key_generator.html`) for generating and managing voucher activation keys.
- **Live Admin Modification Sync**: Dynamically syncs changes to subscription duration, expiry dates, or active status directly from the Cloud database.

### 📦 8. Personal JSON Backup & Restore Engine
- **Full Database Export**: Serializes all academic profiles, courses, schedules, syllabus tasks, and instructor metadata into a structured `.json` backup file.
- **System Share Sheet Integration**: Direct export via Android native share sheet (`share_plus`).
- **Validation & Smart Merge / Clean Overwrite**: Validates backup schema integrity and supports either clean overwrite or timestamp-aware smart merging (preserves newer local task states).

### 📋 9. Diagnostic Activity Logging (`AppLogService`)
- **Comprehensive Audit Trail**: Records operations across categories (`Action`, `Sync`, `Alarm`, `Database`, `Auth`, `System`).
- **In-App Activity Logs Viewer**: Searchable, filterable audit log viewer with real-time log counters and one-tap clipboard/export functionality.

### 🔒 10. Security, Calendar Export & Danger Zone
- **Biometric App Lock**: Fingerprint, Face ID, and Device PIN/Pattern fallback via `local_auth`.
- **RFC 5545 `.ics` Export**: Export your complete semester timetable directly into Google Calendar, Apple Calendar, or clean shareable text.
- **Authentication Flexibility**: Email/Password authentication, Google OAuth 2.0, or full Offline Guest Mode.
- **Danger Zone Utilities**: Force cache re-indexing and cloud account deletion with double confirmation modals.

### 🚀 11. GitHub Releases Auto-Update Engine
- **Direct GitHub API Integration**: Checks `OwndinSwan/SemBase` releases against the installed semantic version (`1.0.7+8`).
- **In-App Update Modal**: Displays release notes and provides direct download and installation gates for the latest APK.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── backup/            # LocalBackupService (JSON export, import, merge)
│   ├── config/            # Centralized Configuration (AppConfig)
│   ├── database/          # Drift SQLite ORM, Tables & Native Connection
│   ├── logging/           # AppLogService (Audit trail & diagnostic daemon)
│   ├── notifications/     # Exact Alarms & Daily Morning Briefing Daemon
│   ├── providers/         # Global Riverpod Singletons (DB, Sync, Subscriptions)
│   ├── services/          # AppUpdateService, SubscriptionService, VacantService
│   ├── sync/              # Transactional Outbox Worker & Cloud Sync Engine
│   └── utils/             # Time Formatter, ICS Calendar Exporter
├── features/
│   ├── archive/           # Academic Term Explorer & History
│   ├── auth/              # Email Auth, Google OAuth, Keystore & Guest Mode
│   ├── cor_parser/        # Regex Matcher & PDF Ingestion Engine
│   ├── dashboard/         # Live Hero Countdown, Daily Timeline, Vacant Modals
│   ├── schedule_grid/     # Weekly 6-Day Grid Timetable & Calendar Sheet
│   ├── settings/          # Settings Dashboard & Sub-Screens
│   │   └── sub_screens/   # Pro Plans, Cloud Sync, Backup, Logs, Security, Danger Zone
│   ├── subject_hub/       # Subject Details, Tasks, Notes, LMS Links
│   ├── sync_diff/         # COR Sync Diff Matcher, Models & Review Dialog
│   └── update/            # In-App Update Modal & Download Gate
└── shared/
    ├── theme/             # Modern Dark Glassmorphic Theme System
    └── widgets/           # Status Badges, Pro Badges, Dialogs, Glass Cards
```

### Core Technologies:
- **Framework**: [Flutter](https://flutter.dev) (v3.29+) / Dart 3.7+
- **State Management**: [Riverpod](https://riverpod.dev) (v2.6.1)
- **Local Database**: [Drift (SQLite)](https://drift.simonbinder.eu) (v2.24.0) with `sqlite3_flutter_libs`
- **Cloud Backend**: [Supabase Flutter](https://supabase.com/docs/reference/dart/start) (v2.8.4)
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

SemBase includes a comprehensive suite of unit and integration tests covering all critical business logic:

```bash
flutter test
```

### Test Coverage:
- **`cor_matcher_test.dart`**: Multi-format COR parsing, split days (*M/TH, T/F, W/S*), military/12h times, room codes, TBA slots.
- **`local_backup_test.dart`**: JSON serialization, schema validation, clean overwrite, and timestamp-aware smart merging.
- **`cloud_sync_test.dart`**: Outbox mutation queue insertion, FIFO draining, and LWW payload handling.
- **`subscription_service_test.dart`**: Pro plan resolution, expiry evaluation, voucher format checking, and days remaining logic.
- **`task_deadline_test.dart`**: Task checklist state transitions, 48-hr urgent query filtering, and deadline date shifting.
- **`time_formatter_test.dart`**: 12h/24h conversion, time ranges, day token mapping, and timezone normalization.
- **`ics_generator_test.dart`**: RFC 5545 calendar file generation and recurrence formatting.
- **`app_log_service_test.dart`**: Audit log recording, category filtering, in-memory buffering, and log export.
- **`app_update_test.dart`**: Semantic version comparison and GitHub update detection.

---

## 📦 Building Release APKs

For detailed environment configuration, Android SDK locking, and troubleshooting, consult [BUILD_GUIDE.md](BUILD_GUIDE.md) and [FLUTTER_ANDROID_UNIVERSAL_BUILD_GUIDE.md](FLUTTER_ANDROID_UNIVERSAL_BUILD_GUIDE.md).

### Split-ABI Release (Recommended for Distribution):
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./build/symbols
```

#### Generated Binaries:
- **`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`** *(Modern Android Devices — ~22.2 MB)*
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

- **[`admin_key_generator.html`](admin_key_generator.html)**: Standalone web portal for administrators to generate and manage 16-character Pro voucher keys in Supabase.
- **[`supabase_subscription_schema.sql`](supabase_subscription_schema.sql)**: Complete PostgreSQL database schema, RLS security policies, and indexes for `subscription_keys` and `user_subscriptions`.
- **[`backup_project.bat`](backup_project.bat)** / **[`restore_project.bat`](restore_project.bat)**: Automated backup and restoration scripts for source code and asset preservation.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ for students everywhere.</sub>
</div>
