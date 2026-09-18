import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/logging/app_log_service.dart';
import 'offline_router_service.dart';

class DownloadProgress {
  final int totalTiles;
  final int downloadedTiles;
  final double downloadedMB;
  final double percent;
  final bool isCompleted;
  final String? error;

  const DownloadProgress({
    required this.totalTiles,
    required this.downloadedTiles,
    required this.downloadedMB,
    required this.percent,
    this.isCompleted = false,
    this.error,
  });
}

class OfflineMapService {
  static const String prefOfflineReady = 'offline_map_ready';
  static const String prefNorth = 'offline_map_north';
  static const String prefSouth = 'offline_map_south';
  static const String prefEast = 'offline_map_east';
  static const String prefWest = 'offline_map_west';
  static const String prefTileCount = 'offline_map_tile_count';
  static const String prefSizeBytes = 'offline_map_size_bytes';
  static const String prefDownloadedAt = 'offline_map_downloaded_at';
  static const String prefCampusCenterLat = 'user_campus_center_lat';
  static const String prefCampusCenterLng = 'user_campus_center_lng';

  // Default fallback territory if no pins, pack or custom center set
  static const LatLng defaultCampusCenter = LatLng(14.4167, 120.9417); // CvSU Imus area
  static const int minDownloadZoom = 12;
  static const int maxDownloadZoom = 16;

  static Future<void> saveUserCampusCenter(LatLng center) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefCampusCenterLat, center.latitude);
    await prefs.setDouble(prefCampusCenterLng, center.longitude);
  }

  static Future<LatLng?> getUserCampusCenter() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(prefCampusCenterLat);
    final lng = prefs.getDouble(prefCampusCenterLng);
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  static Future<String> getTileStorageDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final tileDir = Directory(p.join(docsDir.path, 'offline_map_tiles'));
    if (!await tileDir.exists()) {
      await tileDir.create(recursive: true);
    }
    return tileDir.path;
  }

  /// Calculates tile coordinates (X, Y) at a given zoom for a LatLng
  static math.Point<int> latLngToTile(LatLng latLng, int zoom) {
    final latRad = latLng.latitude * math.pi / 180.0;
    final n = math.pow(2.0, zoom);
    final x = ((latLng.longitude + 180.0) / 360.0 * n).floor();
    final y = ((1.0 - math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi) / 2.0 * n).floor();
    return math.Point(x, y);
  }

  /// Estimates the number of tiles and download size in MB for a given bounding box
  static Map<String, dynamic> estimateDownloadSize(LatLngBounds bounds, {int minZoom = minDownloadZoom, int maxZoom = maxDownloadZoom}) {
    int totalTiles = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final nw = latLngToTile(bounds.northWest, z);
      final se = latLngToTile(bounds.southEast, z);

      final minX = math.min(nw.x, se.x).toInt();
      final maxX = math.max(nw.x, se.x).toInt();
      final minY = math.min(nw.y, se.y).toInt();
      final maxY = math.max(nw.y, se.y).toInt();

      final countX = (maxX - minX + 1);
      final countY = (maxY - minY + 1);
      totalTiles += (countX * countY);
    }

    // Average raster tile is ~15-20 KB
    final estimatedBytes = totalTiles * 18000;
    final estimatedMB = (estimatedBytes / (1024 * 1024));

    return {
      'totalTiles': totalTiles,
      'estimatedMB': double.parse(estimatedMB.toStringAsFixed(1)),
    };
  }

  /// Checks if an offline package is active and cached
  static Future<bool> isOfflineReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefOfflineReady) ?? false;
  }

  /// Retrieves the stored bounding box of the active offline pack
  static Future<LatLngBounds?> getSavedBounds() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(prefNorth)) return null;

    final north = prefs.getDouble(prefNorth);
    final south = prefs.getDouble(prefSouth);
    final east = prefs.getDouble(prefEast);
    final west = prefs.getDouble(prefWest);

    if (north == null || south == null || east == null || west == null) return null;

    return LatLngBounds(
      LatLng(south, west),
      LatLng(north, east),
    );
  }

  /// Retrieves summary statistics of the cached offline pack
  static Future<Map<String, dynamic>> getOfflineStorageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final isReady = prefs.getBool(prefOfflineReady) ?? false;
    final tileCount = prefs.getInt(prefTileCount) ?? 0;
    final sizeBytes = prefs.getInt(prefSizeBytes) ?? 0;
    final downloadedAt = prefs.getString(prefDownloadedAt) ?? 'Never';

    final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return {
      'isReady': isReady,
      'tileCount': tileCount,
      'sizeMB': double.tryParse(sizeMB) ?? 0.0,
      'downloadedAt': downloadedAt,
    };
  }

  /// Downloads map tiles and road routing data strictly inside the specified bounding box
  static Stream<DownloadProgress> downloadOfflinePack(
    LatLngBounds bounds, {
    int minZoom = minDownloadZoom,
    int maxZoom = maxDownloadZoom,
  }) async* {
    final baseStorageDir = await getTileStorageDirectory();
    final client = http.Client();

    final List<Map<String, dynamic>> tilesToFetch = [];

    for (int z = minZoom; z <= maxZoom; z++) {
      final nw = latLngToTile(bounds.northWest, z);
      final se = latLngToTile(bounds.southEast, z);

      final minX = math.min(nw.x, se.x).toInt();
      final maxX = math.max(nw.x, se.x).toInt();
      final minY = math.min(nw.y, se.y).toInt();
      final maxY = math.max(nw.y, se.y).toInt();

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          tilesToFetch.add({'z': z, 'x': x, 'y': y});
        }
      }
    }

    final totalTiles = tilesToFetch.length;
    int downloadedTiles = 0;
    int totalBytes = 0;

    AppLogService.info(
      AppLogService.catApp,
      'Starting offline map pack download: $totalTiles tiles for bounds $bounds',
    );

    yield DownloadProgress(
      totalTiles: totalTiles,
      downloadedTiles: 0,
      downloadedMB: 0.0,
      percent: 0.0,
    );

    // Fetch tiles with concurrency pool
    final mirrorUrls = [
      'https://tile.openstreetmap.org',
      'https://tile.openstreetmap.de',
      'https://a.tile.openstreetmap.fr/osmfr',
    ];
    int mirrorIndex = 0;

    const int chunkSize = 6;
    for (int i = 0; i < tilesToFetch.length; i += chunkSize) {
      final chunk = tilesToFetch.sublist(i, math.min(i + chunkSize, tilesToFetch.length));

      await Future.wait(
        chunk.map((tile) async {
          final z = tile['z'] as int;
          final x = tile['x'] as int;
          final y = tile['y'] as int;

          final zDir = Directory(p.join(baseStorageDir, '$z', '$x'));
          if (!await zDir.exists()) {
            await zDir.create(recursive: true);
          }
          final tileFile = File(p.join(zDir.path, '$y.png'));

          if (await tileFile.exists()) {
            final len = await tileFile.length();
            // If file is valid tile (> 800 bytes, not a tiny error response)
            if (len > 800) {
              totalBytes += len;
              downloadedTiles++;
              return;
            } else {
              try {
                await tileFile.delete();
              } catch (_) {}
            }
          }

          // Clean OpenStreetMap Tile Mirrors (No Deprecated a/b/c Subdomains)
          final baseTileUrl = mirrorUrls[mirrorIndex % mirrorUrls.length];
          mirrorIndex++;
          final url = Uri.parse('$baseTileUrl/$z/$x/$y.png');

          try {
            final res = await client.get(url, headers: {
              'User-Agent': 'SemBase/1.0.8 (com.classbase.sembase; Android Academic Campus Navigator; mailto:contact@sembase.app)',
              'Accept': 'image/png,image/webp,image/*,*/*',
            }).timeout(const Duration(seconds: 10));

            if (res.statusCode == 200 && res.bodyBytes.length > 500) {
              await tileFile.writeAsBytes(res.bodyBytes);
              totalBytes += res.bodyBytes.length;
            }
          } catch (_) {
            // Ignore transient error
          }
          downloadedTiles++;
        }),
      );

      // Friendly 30ms throttle between chunks to adhere to OSM community usage guidelines
      await Future.delayed(const Duration(milliseconds: 30));

      final mb = totalBytes / (1024 * 1024);
      final percent = totalTiles > 0 ? (downloadedTiles / totalTiles) : 1.0;

      yield DownloadProgress(
        totalTiles: totalTiles,
        downloadedTiles: downloadedTiles,
        downloadedMB: double.parse(mb.toStringAsFixed(2)),
        percent: percent,
      );
    }

    client.close();

    // Also download & generate the offline road routing graph for the bounding box
    await OfflineRouterService.downloadAndSaveRoadNetwork(bounds);

    // Persist offline package metadata in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefOfflineReady, true);
    await prefs.setDouble(prefNorth, bounds.north);
    await prefs.setDouble(prefSouth, bounds.south);
    await prefs.setDouble(prefEast, bounds.east);
    await prefs.setDouble(prefWest, bounds.west);
    await prefs.setInt(prefTileCount, downloadedTiles);
    await prefs.setInt(prefSizeBytes, totalBytes);
    await prefs.setString(prefDownloadedAt, DateTime.now().toIso8601String());

    AppLogService.info(
      AppLogService.catApp,
      'Offline map pack download completed: $downloadedTiles tiles, ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    yield DownloadProgress(
      totalTiles: totalTiles,
      downloadedTiles: downloadedTiles,
      downloadedMB: double.parse((totalBytes / (1024 * 1024)).toStringAsFixed(2)),
      percent: 1.0,
      isCompleted: true,
    );
  }

  /// Deletes the offline package and clears cached tiles from storage
  static Future<void> deleteOfflinePack() async {
    try {
      final baseStorageDir = await getTileStorageDirectory();
      final dir = Directory(baseStorageDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      await OfflineRouterService.clearRoadNetwork();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefOfflineReady);
      await prefs.remove(prefNorth);
      await prefs.remove(prefSouth);
      await prefs.remove(prefEast);
      await prefs.remove(prefWest);
      await prefs.remove(prefTileCount);
      await prefs.remove(prefSizeBytes);
      await prefs.remove(prefDownloadedAt);

      AppLogService.info(AppLogService.catApp, 'Deleted offline map pack and cleared storage');
    } catch (e) {
      AppLogService.error(AppLogService.catApp, 'Error deleting offline pack: $e');
    }
  }
}

/// Custom Tile Provider that loads directly from the local offline filesystem
class OfflineFileTileProvider extends TileProvider {
  final String baseDirectory;

  OfflineFileTileProvider({required this.baseDirectory});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final filePath = p.join(
      baseDirectory,
      '${coordinates.z}',
      '${coordinates.x}',
      '${coordinates.y}.png',
    );
    final file = File(filePath);

    if (file.existsSync()) {
      try {
        final len = file.lengthSync();
        if (len > 800) {
          return FileImage(file);
        } else {
          file.deleteSync();
        }
      } catch (_) {}
    }

    // Fallback to official OpenStreetMap tile server
    return NetworkImage(
      'https://tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
      headers: const {
        'User-Agent': 'SemBase/1.0.8 (com.classbase.sembase; Android Academic Campus Navigator; mailto:contact@sembase.app)',
      },
    );
  }
}
