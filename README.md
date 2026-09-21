<div align="center">

# 🎓 SemBase
**Modern, Offline-First Academic Timetable, Interactive Campus Map Hub & Task Vault for Students**

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Drift%202.24-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud%20Vault-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Gemini AI](https://img.shields.io/badge/AI%20Engine-Gemini%20Rotation-8E75FF?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)
[![Android](https://img.shields.io/badge/Android-SDK%2026--36-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/OwndinSwan/SemBase/releases)
[![Tests](https://img.shields.io/badge/Tests-65%20Passing-brightgreen?style=for-the-badge&logo=flutter)](test/)
[![Version](https://img.shields.io/badge/Version-v2.0.1%2B2029-blue?style=for-the-badge)](pubspec.yaml)
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

**SemBase** is an advanced, standalone Android application built with **Flutter 3.29+** and **Dart 3.7+**, engineered specifically for university and college students. It unifies **zero-latency local-first storage (Drift SQLite)** with **transactional cloud synchronization (Supabase)**, automated Certificate of Registration (COR) PDF ingestion with isolate parsing and a multi-model **Gemini Cloud AI quota rotation cascade**, an **interactive campus navigation Map Hub with 100% offline vector/raster maps and multi-modal commute routing**, interactive weekly timetable grid with pinch-to-zoom and side-by-side collision handling, pre-class push notifications with custom vibration alerts, smart vacant break calculation, personal JSON backup & timestamp-aware smart merge, RFC 5545 `.ics` calendar export, and a Pro voucher activation engine.

> [!NOTE]
> SemBase utilizes **system push notifications and device vibration alerts** for all class reminders, morning briefings, and arrival geofencing, ensuring minimal battery impact without interfering with device alarm channels.

---

## ✨ Key Features

### ⚡ 1. Local-First & Zero-Latency Performance
- **100% Offline Capability**: All academic profiles, courses, schedule slots, syllabus tasks, prof metadata, campus POI pins, offline map tiles, and diagnostic logs are persisted locally in an optimized Drift SQLite database.
- **Instant Response (<10ms)**: Adding tasks, shifting deadlines, toggling checklist items, recalibrating campus pins, or switching screens occurs with zero UI blocking or network dependencies.
- **Reactive Stream Architecture**: UI components bind directly to Drift reactive stream providers (`watchCourses()`, `watchPendingCount()`, `watchCampusPins()`, `watchActiveProfile()`, etc.).

### 🗺️ 2. Interactive Campus Map Hub & 100% Offline Navigation
- **Offline OpenStreetMap Engine**: Download high-resolution vector/raster map tile packs (up to **Max Zoom 18**) for zero-data navigation on campus grounds.
- **Overpass API Road Graph Caching**: On-device topological road network pathfinding powered by local shortest-path algorithms (A* / Dijkstra) without requiring external routing APIs.
- **Multi-Modal Commute Strategy & Fare Estimator**:
  - 🚶 **Walking**: Pedestrian paths with accurate walking speed ETAs.
  - 🛵 **Angkas / Motor Taxi**: Shortcut-aware routing with real-time base fare + per-km calculations.
  - 🚌 **Jeepney / PUV**: Highway corridor routing with automatic **20% Philippine Student Fare Discount** calculations.
  - 🚗 **Grab / Private Car**: Traffic-weighted main arterial routing and fare estimations.
- **Smart Overview & Campus Focus Button**: One-tap smart camera recentering that dynamically frames the active navigation route, enrolled class buildings, or downloaded map boundary.

### 📍 3. Precision Campus POI & Home Pin Placement Engine
- **4-Direction D-Pad Nudge Controller**: Fine-tune building locations with **1m, 3m, and 8m** step increments for millimeter-accurate classroom positioning.
- **Ghost Preview & Center Calibration**: Visual semi-transparent pin indicator showing exact coordinate placement before saving.
- **Dorm / Home Residence Pinning**: Set your home base or dorm location to instantly calculate travel times and start commute routes to your next class.
- **Enrolled Classroom Locator**: Directly links enrolled subject room codes (e.g., *CL1, RM.5, IT-Bldg*) to pinned campus structures for instant navigation.

### 🛰️ 4. Background Navigation Tracking & Proximity Arrival Alerts
- **Android Foreground Service**: Persistent live route progression notification with distance remaining, current ETA, and live progress bar while the app is minimized.
- **Geofence Proximity Arrival Alerts**: Automatically triggers a heads-up notification and custom vibration alert when entering the customizable arrival radius (15m–50m) of your destination building.
- **Settings Toggle**: Optional user toggle in Settings to enable or disable background tracking based on preference.

### 🤖 5. Dual Ingestion: Local Isolate COR Parser & Gemini Cloud AI Rotation Cascade
- **Background Isolate PDF Parsing**: Fast on-device document extraction powered by `syncfusion_flutter_pdf` in a dedicated background isolate (`cor_isolate.dart`).
- **Universal Academic Regex Matcher (`CorMatcher`)**: Extracts Student Number, Section (e.g., *BSCS 3-1, BSIT-2A*), Academic Year, Semester, Subject Codes, Titles, Split Days (*M/TH, T/F, W/S, TTH, MW*), Class Timestamps (*12-hr AM/PM and 24-hr military*), Split Rooms (*CL1/RM.5*), and TBA slots.
- **Cloud AI (Gemini) Fallback & Rotation Cascade (`GeminiCorParserService`)**: For complex, irregular, or unstandardized academic documents, SemBase routes extraction to Cloud AI with an automated quota rotation cascade across multiple free-tier model buckets (`sembase-2.5-flash-lite`, `sembase-3.1-flash-lite`, `sembase-3.5-flash-lite`, `sembase-2.5-flash`, `sembase-3.5-flash`, `sembase-3.6-flash`, `sembase-3.7-flash`, `sembase-3-flash-preview`).
- **Quota Error Sanitization & Delay Extraction**: Automatically captures rate limits (`429 / RESOURCE_EXHAUSTED`), extracts server `retryDelay`, cycles smoothly to the next model tier, and presents clean user-facing status banners.
- **Supabase Edge Function Architecture**: Production calls route securely through the `parse-cor` Supabase Edge Function with direct Google Generative AI API fallback.

### 🔄 6. Transactional Cloud Sync & Outbox Queue
- **Transactional FIFO Outbox (`sync_queue`)**: All local mutations (INSERT, UPDATE, DELETE, UPSERT for courses, tasks, and campus pins) are recorded in an atomic SQLite outbox and dispatched automatically upon network reconnection.
- **Cross-Device Real-Time Sync**: Synchronizes schedule, task, and map pin updates between devices in **<500ms** via Supabase Realtime WebSockets.
- **Last-Write-Wins (LWW) Conflict Resolution**: Protects against data overwrite collisions during simultaneous multi-device offline operations.
- **Multi-Account Switching Safety**: Detects account changes on shared devices and prevents data pollution by offering fresh cloud pull or local adoption.
- **Live Connectivity Status Badge**: Displays real-time cloud connection health across all screens.

### 🔍 7. Granular Visual Sync Diff Engine (`SyncDiffService`)
- **Granular Visual Diff Preview**: Compares incoming COR schedules with the active database, clearly highlighting added, modified, unchanged, and dropped courses.
- **Smart Task & Notes Preservation**: Automatically preserves existing course syllabus tasks, deadlines, and instructor LMS metadata when updating or re-importing an existing semester schedule.
- **Academic History Archival**: Cleanly archives previous semester courses for future reference in the Archive Explorer without cluttering active schedules.

### 📅 8. Interactive Weekly Timetable Grid & Daily Timeline
- **Pinch-to-Zoom & Pan Schedule Grid**: Interactive 6-day timetable with smooth multi-touch scaling, auto-hiding zoom buttons, bottom-safe navigation insets, and high-contrast color coding.
- **Side-by-Side Overlap Clustering**: Renders overlapping or simultaneous class schedules side-by-side with proportional column widths to prevent visual clipping.
- **Live Class Countdown Hero**: Real-time progress bar (updated every second) calculating exact time remaining for active classes and showing up-next subjects with room locator.
- **Urgent Tasks Card**: Proactively surfaces upcoming academic deadlines within a 48-hour window with instant completion toggles and one-tap +/- 1-week deadline shifters.
- **Morning Briefing Banner**: Daily schedule overview highlighting start time, total class load, and finish time.

### ☕ 9. Smart Vacant Period Engine
- **Mathematical Interval-Merge Algorithm**: Computes vacant periods across all active days (`M` through `S`), merging multi-section classes into continuous spans with zero false gaps.
- **Interactive Vacant Customization**: Tap any vacant block to assign custom activity labels (*Lunch Break, Study Session, Library Time, Gym / Workout, Org Meeting*), modify time windows, or hide/delete vacant blocks.

### 🔔 10. Pre-Class Push Notifications & Morning Schedule Digest
- **Heads-Up Push Notifications & Vibration Alerts**: Scheduled via `flutter_local_notifications` with customizable lead times (5, 10, 15, 30, 45, or 60 minutes) before class starts.
- **Distinct Vibration Feedback**: Employs distinct haptic vibration patterns to notify students of upcoming classes and geofence arrivals discreetly.
- **Daily 7:00 AM Morning Briefing**: Sends a daily digest push notification summarizing the day's class timeline and upcoming assignments.
- **Battery Optimization Friendly**: Push notifications and background services operate efficiently without battery drain.

### 💎 11. Pro Subscription & Cloud Voucher Activation System
- **Tier Architecture**: Offers Free Academic and Pro tiers (Monthly, Semester Pass, Lifetime Degree).
- **Online Cloud Voucher Redemption**: 16-character activation code redemption backed by Supabase `subscription_keys` and `user_subscriptions` tables.
- **Hardware-Encrypted Secure Storage**: Encrypts and caches activation credentials using `flutter_secure_storage` with Android KeyStore integration.
- **Admin Voucher Key Generator**: Companion standalone HTML utility ([`admin_key_generator.html`](admin_key_generator.html)) for generating and managing voucher activation keys in Supabase.
- **Live Admin Modification Sync**: Dynamically syncs changes to subscription duration, expiry dates, or active status directly from the cloud database.

### 📦 12. Personal JSON Backup & Restore Engine
- **Full Database Export**: Serializes all academic profiles, courses, schedules, syllabus tasks, campus pins, and instructor metadata into a structured `.json` backup file.
- **System Share Sheet Integration**: Direct export via Android native share sheet (`share_plus`).
- **Validation & Smart Merge / Clean Overwrite**: Validates backup schema integrity and supports either clean overwrite or timestamp-aware smart merging (preserves newer local task completions when importing older backups).

### 📆 13. RFC 5545 iCalendar (`.ics`) & Plaintext Timetable Export
- **RFC 5545 `.ics` Export**: Export your complete semester timetable into standardized `.ics` calendar files compatible with Google Calendar, Apple Calendar, and Microsoft Outlook.
- **Plaintext Timetable Sharing**: Formats and copies a clean, human-readable class schedule to the clipboard for instant messaging and social sharing.

### 🔒 14. Security, Biometrics & Danger Zone
- **Biometric App Lock**: Fingerprint, Face ID, and Device PIN/Pattern fallback via `local_auth`.
- **Authentication Flexibility**: Email/Password authentication, Google OAuth 2.0, or full Offline Guest Mode.
- **Danger Zone Utilities**: Force cache re-indexing, local database reset, and cloud account deletion with animated confirmation modals.

### 📋 15. Diagnostic Activity Logging (`AppLogService`)
- **Comprehensive Audit Trail**: In-memory ring buffer and persistent logging across categories (`ACTION`, `SYNC`, `NOTIFICATION`, `DATABASE`, `AUTH`, `SYSTEM`, `MAP`).
- **In-App Activity Logs Viewer**: Searchable, filterable audit log viewer with real-time category chips, clear log options, and one-tap clipboard/export functionality.

### 🚀 16. GitHub Releases Auto-Update Engine
- **Direct GitHub API Integration**: Checks `OwndinSwan/SemBase` releases against the installed semantic version (`2.0.1+2029`).
- **In-App Update Modal**: Displays clean markdown release notes and provides direct download and installation gates for the latest APK.

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
│   ├── notifications/     # Class Push Notifications & Daily Morning Briefing Daemon
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
│   ├── map/               # Campus Map Hub, Offline OSM Vector/Raster, Overpass Router
│   │   ├── models/        # Campus Pin, Route Path, Commute Strategy Models
│   │   ├── screens/       # CampusMapScreen, OfflineMapPackScreen, RouteDetailsScreen
│   │   ├── services/      # OfflineMapService, OfflineRouterService, CampusProximityService
│   │   └── widgets/       # D-Pad Nudge Controller, Commute Mode Selector, Ghost Pin
│   ├── schedule_grid/     # Weekly 6-Day Grid Timetable, Pinch-to-Zoom & Overlap Layout
│   ├── settings/          # Settings Dashboard & Sub-Screens
│   │   └── sub_screens/   # Pro Plans, Cloud Sync, Backup, Logs, Security, Map Settings, Danger Zone
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
- **Mapping & Geolocation**: [flutter_map](https://pub.dev/packages/flutter_map) (v7.0.2), `latlong2`, `geolocator` (v13.0.2)
- **Cloud Backend**: [Supabase Flutter](https://supabase.com/docs/reference/dart/start) (v2.8.4)
- **AI Document Extraction**: Google Gemini Cloud AI via Supabase Edge Functions with multi-model quota rotation
- **PDF Engine**: [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf) (v28.2.12)
- **Push Notifications & Haptics**: `flutter_local_notifications` (v18.0.1) & `vibration` (v2.0.1)
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

SemBase includes a comprehensive suite of **65 unit and integration tests** across 11 test suites covering all critical business logic:

```bash
flutter test
```

### Test Coverage (11 Test Suites • 65 Passing):
- **`cor_matcher_test.dart`**: Multi-format COR parsing, split days (*M/TH, T/F, W/S, TTH, MW*), military/12h times, room codes, TBA slots.
- **`gemini_cor_parser_test.dart`**: Multi-model quota rotation cascade, 429 / `RESOURCE_EXHAUSTED` rate limit detection, `retryDelay` parsing, branded error sanitization (`sembase-`), and daily midnight reset logic.
- **`map_and_campus_pinning_test.dart`**: Campus POI CRUD, distinct enrolled schedule rooms, Web Mercator tile calculations, offline tile bounding box estimation, pathfinding interpolation, geofence arrival proximity alerts, sync outbox mutations, and multi-modal commute calculations (Walking, Angkas, Jeepney student fare, Grab).
- **`local_backup_test.dart`**: JSON serialization, schema validation, clean overwrite, campus pin serialization, and timestamp-aware Smart Merge (preserves newer local task states).
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
- **`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`** *(Modern 64-bit Android Devices — ~22.6 MB)*
- **`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`** *(32-bit Legacy Android Devices — ~20.1 MB)*
- **`build/app/outputs/flutter-apk/app-x86_64-release.apk`** *(Emulators & x86_64 Devices — ~24.1 MB)*

### Universal Fat APK (All Architectures in One File):
```bash
flutter build apk --release --no-split-per-abi --obfuscate --split-debug-info=./build/symbols
```

---

## 🔄 GitHub Auto-Update Workflow

SemBase automatically detects new releases published on GitHub:

1. Update `version` in [`pubspec.yaml`](pubspec.yaml) and `AppConfig.appVersion` in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart) (e.g., `2.0.1+2029`).
2. Build release APK (`app-arm64-v8a-release.apk`).
3. Navigate to [GitHub Releases > Draft a New Release](https://github.com/OwndinSwan/SemBase/releases/new).
4. Set the tag to match your new version (e.g., **`v2.0.1`**).
5. Attach `app-arm64-v8a-release.apk` to the release assets and click **Publish Release**.
6. Installed SemBase apps will automatically detect the new release and present the in-app update banner.

---

## 🛠️ Companion Utilities

- **[`admin_key_generator.html`](admin_key_generator.html)**: Standalone web portal for administrators to generate, manage, and directly register 16-character Pro voucher keys in Supabase.
- **[`supabase_subscription_schema.sql`](supabase_subscription_schema.sql)**: Complete PostgreSQL database schema, RLS security policies, and indexes for `subscription_keys` and `user_subscriptions`.
- **[`backup_project.bat`](backup_project.bat)** / **[`restore_project.bat`](restore_project.bat)** / **[`create_backup.ps1`](create_backup.ps1)**: Automated backup and restoration scripts for clean source code and asset preservation.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ for students everywhere.</sub>
</div>
