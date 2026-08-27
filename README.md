<div align="center">

# 🎓 SemBase
**Modern, Offline-First Academic Timetable, Task Vault & Cloud Synchronizer for Students**

[![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Drift%202.24-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud%20Vault-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Android](https://img.shields.io/badge/Platform-Android%20APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/OwndinSwan/SemBase/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <a href="#-key-features">Key Features</a> •
  <a href="#-architecture--tech-stack">Architecture</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-building-release-apks">Building APKs</a> •
  <a href="#-github-auto-update">Auto-Update</a> •
  <a href="#-project-structure">Project Structure</a>
</p>

</div>

---

## 📖 Overview

**SemBase** is a standalone, high-performance Android mobile application built with **Flutter**, designed specifically for college students. It combines **zero-latency local-first storage (Drift SQLite)** with **transactional cloud synchronization (Supabase)**, automated Certificate of Registration (COR) parsing, and exact class alarms that operate independently of third-party calendar apps.

---

## ✨ Key Features

### ⚡ 1. Local-First & Zero-Latency Performance
- **100% Offline Capability**: All courses, schedules, syllabus tasks, and metadata are stored in a local SQLite database (`drift`).
- **Instant Response (<10ms)**: Adding tasks, checking checkboxes, or switching tabs occurs with zero network latency.

### 🔄 2. Transactional Cloud Sync & Outbox Queue
- **Automated Reconnection Sync**: Operates seamlessly offline; mutations are queued in a persistent FIFO `sync_queue` table and dispatched automatically when internet connectivity is detected.
- **Cross-Device Real-Time Sync**: Synchronizes schedule and task changes between multiple devices in **<500ms** via Supabase Realtime WebSockets.
- **Last-Write-Wins (LWW) Conflict Resolution**: Prevents data loss during simultaneous multi-device offline updates.
- **Multi-Account Switching Guard**: Detects account switches on shared devices and prompts the user to either start fresh (pull cloud vault) or adopt the local schedule.

### 📄 3. Intelligent COR & Syllabus Parser
- **Direct PDF & Plain Text Ingestion**: Parses university Certificate of Registration (COR) documents and syllabus schedule formats.
- **Pre-configured Cavite State University (CvSU) & General Format Parser**: Automatically extracts Student Number, Section (e.g. *BSIT-2A*), Academic Year, Semester, Subject Codes, Titles, Split Days (*M/TH, T/F, W/S*), Class Timestamps (*12-hr AM/PM and 24-hr military*), Split Rooms (*CL1/RM.5*), and TBA slots.

### 📅 4. Dynamic Weekly Schedule Grid & Daily Timeline
- **Live Class Countdown Hero**: Displays active class countdown progress bars (updated every second) and up-next class indicators.
- **Color-Coded Subject Grid**: High-contrast weekly calendar layout with bottom-safe insets for gesture navigation.
- **Subject Search & Filter**: Filter subjects by active tasks, upcoming deadlines, or search query.

### ☕ 5. Smart Vacant Period Engine
- **Mathematical Interval-Merge Algorithm**: Computes vacant periods across all days (`M` through `S`), merging multi-section classes into continuous spans with zero false gaps.
- **Interactive Vacant Customization**: Tap any vacant block to assign custom labels (*Lunch Break, Study Session, Library Time, Gym / Workout, Org Meeting*), adjust time ranges, or delete/hide the block.

### 🔔 6. Standalone Class Alarms & Daily Morning Briefings
- **Exact Native Android Alarms**: Uses `android_alarm_manager_plus` and `flutter_local_notifications` for exact 15-minute pre-class alarms.
- **Daily 7:00 AM Morning Briefing**: Sends a daily schedule digest summarizing the day's class timeline.

### 🚀 7. GitHub Releases Auto-Update Engine
- **Direct GitHub API Integration**: Checks `OwndinSwan/SemBase` releases against the installed semantic version.
- **In-App Update Banner & Modal**: Prompts the user with release notes and a direct download/install button for the latest release APK.

### 🔒 8. Security & Export Utilities
- **Biometric App Lock**: Fingerprint, Face ID, and Device PIN/Pattern fallback.
- **RFC 5545 `.ics` Export**: Export your semester schedule into Google Calendar, Apple Calendar, or clean shareable text.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── config/            # Centralized Configuration (AppConfig)
│   ├── database/          # Drift SQLite ORM & Outbox Mutations Table
│   ├── notifications/     # Exact Alarms & Notification Daemon
│   ├── providers/         # Global Riverpod Singletons (DB, Sync, Auth)
│   ├── services/          # GitHub Update Service, Vacant Service
│   ├── sync/              # Transactional Outbox Worker & Cloud Sync Engine
│   └── utils/             # Time Formatter, ICS Calendar Exporter
├── features/
│   ├── archive/           # Academic Term Explorer & History
│   ├── auth/              # Email Auth, Google OAuth, Offline Guest Mode
│   ├── cor_parser/        # Regex Matcher & PDF Ingestion Engine
│   ├── dashboard/         # Live Hero Countdown, Daily Timeline View
│   ├── schedule_grid/     # Weekly 6-Day Grid Timetable
│   ├── settings/          # Data Vault, Alarms, Biometrics, Password
│   ├── subject_hub/       # Subject Details, Tasks, Notes, LMS Links
│   └── update/            # Force Update Modal & Download Gate
└── shared/
    ├── theme/             # Modern Dark Glassmorphic Theme System
    └── widgets/           # Status Badges, Dialogs, Custom UI Components
```

- **Framework**: [Flutter](https://flutter.dev) (v3.29+) / Dart 3.7+
- **State Management**: [Riverpod](https://riverpod.dev) (v2.6+)
- **Local Database**: [Drift (SQLite)](https://drift.simonbinder.eu) with `sqlite3_flutter_libs`
- **Cloud Backend**: [Supabase Flutter](https://supabase.com/docs/reference/dart/start)
- **PDF Engine**: [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf)
- **Alarms & Notifications**: `android_alarm_manager_plus` & `flutter_local_notifications`
- **Biometrics & Keystore**: `local_auth` & `flutter_secure_storage`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.29.0`)
- [Android Studio](https://developer.android.com/studio) / Android SDK (`API Level 21+`)
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

### 5. Run Automated Tests
```bash
flutter test
```

---

## 📦 Building Release APKs

To compile optimized, obfuscated release APKs:

```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./build/symbols
```

### Output Binaries:
- **`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`** *(Modern Android Devices / Samsung Galaxy)*
- **`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`** *(32-bit Legacy Android Devices)*
- **`build/app/outputs/flutter-apk/app-x86_64-release.apk`** *(Emulators & x86_64 Devices)*

---

## 🔄 Publishing an Update on GitHub

SemBase detects new releases automatically from the repository:

1. Build the release APK (`app-arm64-v8a-release.apk`).
2. Navigate to [GitHub Releases > Draft a New Release](https://github.com/OwndinSwan/SemBase/releases/new).
3. Set tag to **`v1.0.1`** (higher than `AppConfig.appVersion`).
4. Attach `app-arm64-v8a-release.apk` to the release assets and click **Publish Release**.
5. All SemBase apps will automatically display the update banner and provide direct download/installation.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ for students everywhere.</sub>
</div>
