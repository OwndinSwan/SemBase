import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;
  final DateTime? publishedAt;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
    this.publishedAt,
  });
}

class AppUpdateService {
  /// Checks GitHub Releases API for new version
  static Future<AppUpdateInfo> checkForUpdates({String? customApiUrl}) async {
    final currentVer = _normalizeVersion(AppConfig.appVersion);
    final apiUrl = customApiUrl ?? AppConfig.githubReleasesApiUrl;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final request = await client.getUrl(Uri.parse(apiUrl));
      request.headers.set('User-Agent', 'SemBase-App-Updater');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        return AppUpdateInfo(
          hasUpdate: false,
          latestVersion: currentVer,
          currentVersion: currentVer,
          releaseName: '',
          releaseNotes: '',
          downloadUrl: AppConfig.githubReleasesWebUrl,
        );
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final tagName = data['tag_name'] as String? ?? '';
      final latestVer = _normalizeVersion(tagName);
      final releaseName = data['name'] as String? ?? 'SemBase Update';
      final releaseNotes = data['body'] as String? ?? 'Performance improvements and bug fixes.';
      final htmlUrl = data['html_url'] as String? ?? AppConfig.githubReleasesWebUrl;
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      // Extract direct APK asset download URL if present
      String downloadUrl = htmlUrl;
      if (data.containsKey('assets') && data['assets'] is List) {
        final assets = data['assets'] as List;
        // 1. Prefer arm64-v8a apk
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          final browserDownloadUrl = asset['browser_download_url'] as String?;
          if (name.contains('arm64-v8a') && browserDownloadUrl != null) {
            downloadUrl = browserDownloadUrl;
            break;
          }
        }
        // 2. Fallback to any .apk asset
        if (downloadUrl == htmlUrl) {
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            final browserDownloadUrl = asset['browser_download_url'] as String?;
            if (name.endsWith('.apk') && browserDownloadUrl != null) {
              downloadUrl = browserDownloadUrl;
              break;
            }
          }
        }
      }

      final hasUpdate = isNewerVersion(latestVer, currentVer);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        latestVersion: latestVer,
        currentVersion: currentVer,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        isMandatory: AppConfig.isForceUpdateMandatory || hasMajorVersionDifference(latestVer, currentVer),
        publishedAt: publishedAt,
      );
    } catch (e) {
      debugPrint('App update check error: $e');
      return AppUpdateInfo(
        hasUpdate: false,
        latestVersion: currentVer,
        currentVersion: currentVer,
        releaseName: '',
        releaseNotes: '',
        downloadUrl: AppConfig.githubReleasesWebUrl,
      );
    }
  }

  /// Normalizes tags like 'v1.2.3+4' -> '1.2.3'
  static String _normalizeVersion(String ver) {
    var cleaned = ver.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.contains('+')) {
      cleaned = cleaned.split('+')[0];
    }
    return cleaned;
  }

  /// Compares two semantic version strings (e.g. '1.1.0' > '1.0.0')
  static bool isNewerVersion(String latest, String current) {
    try {
      final lParts = _normalizeVersion(latest).split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final cParts = _normalizeVersion(current).split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (lParts.length < 3) {
        lParts.add(0);
      }
      while (cParts.length < 3) {
        cParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if major version bumped (e.g. 2.0.0 vs 1.0.0)
  static bool hasMajorVersionDifference(String latest, String current) {
    try {
      final lMajor = int.tryParse(_normalizeVersion(latest).split('.')[0]) ?? 0;
      final cMajor = int.tryParse(_normalizeVersion(current).split('.')[0]) ?? 0;
      return lMajor > cMajor;
    } catch (_) {
      return false;
    }
  }
}
