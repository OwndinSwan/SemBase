<div align="center">

# 🎓 SemBase
**Modern, Offline-First Academic Timetable, Task Vault, Class Treasury Audit & Interactive Campus Map Hub**

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Drift%202.24-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Supabase](https://img.shields.io/badge/Supabase-Cloud%20Vault-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Gemini AI](https://img.shields.io/badge/AI%20Engine-Gemini%20Cascade-8E75FF?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)
[![Android](https://img.shields.io/badge/Android-SDK%2026--36-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/OwndinSwan/SemBase/releases)
[![Version](https://img.shields.io/badge/Version-v2.0.2%2B4049-blue?style=for-the-badge)](pubspec.yaml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-key-features">Key Features</a> •
  <a href="#-public-audit-web-portal">Public Audit Web</a> •
  <a href="#-architecture--tech-stack">Architecture</a> •
  <a href="#-project-structure">Project Structure</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-building-release-apks">Building APKs</a> •
  <a href="#-github-auto-update">Auto-Update</a> •
  <a href="#-legal--compliance">Legal & Compliance</a>
</p>

</div>

---

## 📖 Overview

**SemBase** is an advanced, standalone Android application built with **Flutter 3.29+** and **Dart 3.7+**, engineered specifically for university and college students, class officers, and treasurers.

It unifies:
1. **Zero-Latency Local Vault**: Drift SQLite local-first storage with instant queries (<10ms).
2. **AI COR Timetable Ingestion**: Isolate-based background PDF parsing and Gemini AI multi-model quota rotation cascade.
3. **Class Treasury & Audit Ledger**: Dues management, student payment tracking (Paid, Partial, Unpaid), contingency funds, and **100% Free Public Web Transparency Links** ([sem-base-web.vercel.app/audit](https://sem-base-web.vercel.app/audit/)).
4. **Interactive Campus Map Hub**: Offline OpenStreetMap navigation, custom waypoint pinning (`RM.8`, `HOME`), and GPS wayfinding.
5. **Philippine Legal Framework & Privacy Compliance**: Full adherence to Republic Act No. 10173 (Data Privacy Act of 2012), RA 10175, and BSP Non-Banking Entity standards with atomic backend account deletion.

---

## ✨ Key Features

### ⚡ 1. Local-First & Zero-Latency Performance
- **100% Offline Capability**: All academic timetables, task vaults, audit ledgers, student balances, and map waypoints reside directly in local SQLite.
- **Instant Response (<10ms)**: Zero UI blocking, instant query execution, and seamless offline mutations.
- **Reactive Stream Architecture**: Binds UI directly to Drift reactive stream providers (`watchCourses()`, `watchAuditProjects()`, `watchPendingCount()`, `watchCampusPins()`).

### 💰 2. Class Treasury & Public Audit Ledger
- **Multi-Treasurer Collaboration**: Delegate treasury duties to class officers with role-based access control.
- **Real-Time Dues Tracking**: Categorize student payment states into `Paid`, `Partial`, and `Unpaid` with custom target amounts per student.
- **Contingency Fund Management**: Track class emergency expenses, supplies purchases, and balance reconciliations with automated percentage metrics.
- **Free Instant Web Transparency Link**: Generate a public read-only link for classmates to verify their balance in any web browser without logging in ([sem-base-web.vercel.app/audit](https://sem-base-web.vercel.app/audit/)).
- **Audit Backup & Restore**: Full export and import of class ledgers, transactions, and student balances within Settings > Personal Data Backup.

### 🗺️ 3. Interactive Campus Map Hub & Navigation
- **Offline OpenStreetMap Engine**: High-resolution vector/raster map tile engine for campus navigation.
- **Custom Waypoints & Geofences**: Pin lecture halls (`RM.8`), campus buildings, and home stations (`HOME`) with millimeter-precision nudge controls.
- **GPS Location & Camera Controls**: Smooth camera transitions to current user position (`🎯`), campus pins (`🎓`), home (`🏠`), and full bounding overview (`[ ]`).

### 🤖 4. AI COR Schedule Ingestion & Multi-Model Cascade
- **Background Isolate Extraction**: High-speed on-device document extraction via `syncfusion_flutter_pdf`.
- **Gemini Multi-Model Quota Rotation**: Automatic failover cascade across free-tier Gemini models for irregular or scanned academic forms.
- **Visual Diff Review**: Compares incoming registration schedules against existing local records with Add, Modify, Drop, and Unchanged breakdowns.

### 📅 5. Weekly Timetable Grid & Task Vault
- **Pinch-to-Zoom Schedule Grid**: Multi-slot timetable with side-by-side overlap clustering and multi-hour lab spans (`10:00 AM - 1:00 PM`).
- **Live UP NEXT Class Countdown**: Real-time progress countdown with TBA room detection and lecture badges.
- **Pinned 48-Hour Deadlines**: Proactively surfaces urgent assignments and exam dates with completion checkboxes.
- **Vacant Break Calculator**: Automated gap calculation for study sessions, breaks, and campus downtime.

### 🔒 6. Security, Philippine Legal Compliance & Privacy
- **Republic Act No. 10173 (DPA 2012) Compliant**: Strict data privacy implementation, local encryption, and zero unauthorized third-party sharing.
- **Stateless Gemini AI Disclosure**: Scanned registration forms are processed ephemerally in RAM and immediately discarded with zero data retention.
- **Atomic Danger Zone Deletion**: One-click account purge via PostgreSQL RPC (`delete_user_account`) that permanently deletes cloud database rows and Supabase Auth credentials.
- **Biometric App Lock**: Fingerprint, Face ID, and device PIN/pattern protection.

---

## 🌐 Public Audit Web Portal

SemBase provides a standalone, zero-cost public transparency web viewer for classmates:

- **Live URL**: [https://sem-base-web.vercel.app/audit/](https://sem-base-web.vercel.app/audit/)
- **Features**:
  - Multi-project tabs (`📁 Class Dues`, `📁 Banquet Fund`).
  - Search roster by student name or student ID.
  - Color-coded payment badges (`PAID`, `PARTIAL`, `UNPAID`).
  - Instant live cloud sync when treasurers record payments.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── backup/            # LocalBackupService (JSON export/import, Audit Merge)
│   ├── config/            # Centralized App Configuration (AppConfig v2.0.2)
│   ├── database/          # Drift SQLite ORM, Tables, Foreign Keys & Migrations
│   ├── logging/           # AppLogService (Audit activity trail ring buffer)
│   ├── notifications/     # Class Push Notifications & Morning Briefing Daemon
│   ├── providers/         # Global Riverpod Singletons (DB, Sync, Subscriptions)
│   ├── services/          # AppUpdateService, SubscriptionService, VacantService
│   └── sync/              # Transactional Outbox Worker & Supabase Cloud Sync Engine
├── features/
│   ├── audit/             # Class Treasury, Multi-Treasurer, Public Shared Link & Ledger
│   │   ├── models/        # AuditProject, StudentBalance, TransactionRecord
│   │   ├── screens/       # AuditHomeScreen, ProjectDetailScreen, PublicShareScreen
│   │   └── widgets/       # TreasurySummaryCard, StudentRosterTile, ContingencyCard
│   ├── auth/              # Email Auth, Google OAuth 2.0, Keystore & Guest Mode
│   ├── cor_parser/        # Isolate PDF Parser, Regex Matcher & Gemini AI Cascade
│   ├── dashboard/         # UP NEXT Countdown, Pinned Deadlines, Daily Timeline
│   ├── legal_compliance/  # Terms Agreement Dialog, Privacy Policy, DPA 2012 Disclosures
│   ├── map/               # Campus Map Hub, Leaflet/OSM Tiles, Pin Calibration
│   ├── schedule_grid/     # Weekly 6-Day Timetable Grid & Overlap Layout
│   ├── settings/          # Settings Dashboard, Personal Data Backup, Danger Zone
│   └── subject_hub/       # Subject Details, Tasks, Notes, LMS Links, ICS Export
└── shared/
    ├── theme/             # Modern Dark Glassmorphic Theme System (AppTheme)
    └── widgets/           # Status Badges, Pro Badges, Animated Dialogs, Glass Cards
```

### Core Technologies:
- **Framework**: [Flutter](https://flutter.dev) (v3.29+) / [Dart](https://dart.dev) (v3.7+)
- **State Management**: [Riverpod](https://riverpod.dev) (v2.6.1)
- **Local Database**: [Drift (SQLite)](https://drift.simonbinder.eu) (v2.24.0) with `sqlite3_flutter_libs`
- **Mapping**: [flutter_map](https://pub.dev/packages/flutter_map) (v7.0.2), `latlong2`, `geolocator`
- **Cloud Backend**: [Supabase Flutter](https://supabase.com/docs/reference/dart/start) (v2.8.4)
- **Document AI**: Google Gemini API with multi-model quota rotation
- **PDF Engine**: [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf) (v28.2.12)
- **Notifications**: `flutter_local_notifications` (v18.0.1)

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

### 4. Run the Application
```bash
flutter run
```

---

## 📦 Building Release APKs

SemBase is configured with **Java 17 desugaring** (`desugar_jdk_libs:2.1.4`) and ProGuard rules for compatibility across all modern and budget Android devices (**Android 8.0+ / API 26+**, Samsung, Itel, Xiaomi, etc.).

### Universal Release APK:
```bash
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk` (~72.6 MB)

### Split-ABI Release:
```bash
flutter build apk --release --split-per-abi
```

---

## 🔄 GitHub Auto-Update Workflow

SemBase automatically detects new releases published on GitHub:

1. Update version in [`pubspec.yaml`](pubspec.yaml) and `AppConfig.appVersion` in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart) (e.g., `2.0.2`).
2. Build the release APK (`flutter build apk --release`).
3. Publish to [GitHub Releases](https://github.com/OwndinSwan/SemBase/releases) with tag **`v2.0.2`**.
4. Installed SemBase apps will automatically prompt students with the in-app update modal and changelog notes.

---

## ⚖️ Legal & Compliance

SemBase is developed in strict accordance with Philippine laws and international privacy standards:
- **Republic Act No. 10173** (Data Privacy Act of 2012)
- **Republic Act No. 10175** (Cybercrime Prevention Act of 2012)
- **Republic Act No. 8792** (Electronic Commerce Act of 2000)
- **Bangko Sentral ng Pilipinas (BSP) Non-Banking Entity Notice**: SemBase is a digital record-keeping utility and does not process, hold, or transmit monetary deposits.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>SemBase • Built with ❤️ for students everywhere.</sub>
</div>
