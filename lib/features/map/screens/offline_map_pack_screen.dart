import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/pro_badge.dart';
import '../../../shared/widgets/pro_gate_dialog.dart';
import '../services/offline_map_service.dart';

class OfflineMapPackScreen extends ConsumerStatefulWidget {
  const OfflineMapPackScreen({super.key});

  @override
  ConsumerState<OfflineMapPackScreen> createState() => _OfflineMapPackScreenState();
}

class _OfflineMapPackScreenState extends ConsumerState<OfflineMapPackScreen> {
  final MapController _mapController = MapController();

  // Bounding box bounds (Default Cavite / Greater Manila region)
  LatLng _center = OfflineMapService.defaultCampusCenter;
  double _boxSpanLat = 0.08;
  double _boxSpanLon = 0.08;

  bool _isDownloading = false;
  DownloadProgress? _downloadProgress;
  StreamSubscription<DownloadProgress>? _downloadSub;

  bool _isPackReady = false;
  Map<String, dynamic> _packStats = {};

  @override
  void initState() {
    super.initState();
    _loadExistingPackStats();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _loadExistingPackStats() async {
    final stats = await OfflineMapService.getOfflineStorageStats();
    final isReady = await OfflineMapService.isOfflineReady();
    final savedBounds = await OfflineMapService.getSavedBounds();

    if (mounted) {
      setState(() {
        _isPackReady = isReady;
        _packStats = stats;
        if (savedBounds != null) {
          _center = savedBounds.center;
          _boxSpanLat = (savedBounds.north - savedBounds.south);
          _boxSpanLon = (savedBounds.east - savedBounds.west);
        }
      });
    }
  }

  LatLngBounds _getCurrentSelectedBounds() {
    final north = _center.latitude + (_boxSpanLat / 2);
    final south = _center.latitude - (_boxSpanLat / 2);
    final east = _center.longitude + (_boxSpanLon / 2);
    final west = _center.longitude - (_boxSpanLon / 2);
    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  void _startDownload() {
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      ProGateDialog.show(
        context,
        featureName: 'Offline Map Pack & Territory Downloader',
        featureDescription:
            'Downloading 100% offline map vector tiles and offline road networks for zero-data commute and campus navigation requires SemBase Pro. Free users have full access to interactive online maps.',
        featureIcon: Icons.download_for_offline_rounded,
      );
      return;
    }

    final bounds = _getCurrentSelectedBounds();
    final estimate = OfflineMapService.estimateDownloadSize(bounds);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.download_for_offline_rounded, color: AppTheme.primaryGreenLight),
            SizedBox(width: 10),
            Text('Download Offline Pack', style: TextStyle(color: AppTheme.textPrimaryDark, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will download all map vector tiles and offline road networks within your framed territory for 100% offline usage.',
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Tiles: ${estimate['totalTiles']}', style: const TextStyle(color: AppTheme.textPrimaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('~${estimate['estimatedMB']} MB', style: const TextStyle(color: AppTheme.primaryGreenLight, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeDownload(bounds);
            },
            child: const Text('Start Download'),
          ),
        ],
      ),
    );
  }

  void _executeDownload(LatLngBounds bounds) {
    setState(() {
      _isDownloading = true;
      _downloadProgress = null;
    });

    HapticFeedback.mediumImpact();

    _downloadSub = OfflineMapService.downloadOfflinePack(bounds).listen(
      (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            if (progress.isCompleted) {
              _isDownloading = false;
              _loadExistingPackStats();
            }
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isDownloading = false);
          AppToast.showError(context, 'Download failed: $err');
        }
      },
    );
  }

  Future<void> _handleDeletePack() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Offline Map Pack?', style: TextStyle(color: AppTheme.textPrimaryDark, fontSize: 16)),
        content: const Text(
          'This will remove all cached map tiles and offline road network data from your device storage.',
          style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRose,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await OfflineMapService.deleteOfflinePack();
      await _loadExistingPackStats();
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Offline map package deleted',
          icon: Icons.delete_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final currentBounds = _getCurrentSelectedBounds();
    final estimate = OfflineMapService.estimateDownloadSize(currentBounds);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Offline Map Pack & Territory',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ProBadge(isProActive: isPro),
          ],
        ),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        actions: [
          if (_isPackReady && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose),
              tooltip: 'Delete Cached Pack',
              onPressed: _handleDeletePack,
            ),
        ],
      ),
      body: Column(
        children: [
          // Top Territory Calibration & Storage Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(bottom: BorderSide(color: AppTheme.borderDark.withOpacity(0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPackReady ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: _isPackReady ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPackReady ? 'Offline Pack Active' : 'No Offline Pack Installed',
                          style: TextStyle(
                            color: _isPackReady ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_isPackReady)
                      Text(
                        '${_packStats['sizeMB'] ?? 0.0} MB (${_packStats['tileCount'] ?? 0} tiles)',
                        style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pan and pinch to frame your home, commute transit routes, and university campus inside the green territory box.',
                  style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11.5),
                ),
              ],
            ),
          ),

          // Interactive Map Viewport with Bounding Box Overlay
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13.0,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                    onPositionChanged: (pos, hasGesture) {
                      if (pos.center != null && !_isDownloading) {
                        setState(() {
                          _center = pos.center!;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.classbase.sembase',
                    ),
                    // Bounding Box Polygon Overlay
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: [
                            LatLng(currentBounds.north, currentBounds.west),
                            LatLng(currentBounds.north, currentBounds.east),
                            LatLng(currentBounds.south, currentBounds.east),
                            LatLng(currentBounds.south, currentBounds.west),
                          ],
                          color: AppTheme.primaryGreen.withOpacity(0.18),
                          borderColor: AppTheme.primaryGreenLight,
                          borderStrokeWidth: 2.5,
                          isFilled: true,
                        ),
                      ],
                    ),
                  ],
                ),

                // Territory Size Adjuster Overlay (Floating Bottom Controls)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.crop_free_rounded, size: 14, color: AppTheme.primaryGreenLight),
                        const SizedBox(width: 6),
                        Text(
                          '~${estimate['estimatedMB']} MB',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Territory Box Size +/- Steppers
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'expand_box',
                        backgroundColor: AppTheme.cardDark,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            _boxSpanLat = math.min(0.20, _boxSpanLat + 0.02);
                            _boxSpanLon = math.min(0.20, _boxSpanLon + 0.02);
                          });
                        },
                        child: const Icon(Icons.zoom_out_map_rounded, size: 18),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'shrink_box',
                        backgroundColor: AppTheme.cardDark,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            _boxSpanLat = math.max(0.03, _boxSpanLat - 0.02);
                            _boxSpanLon = math.max(0.03, _boxSpanLon - 0.02);
                          });
                        },
                        child: const Icon(Icons.zoom_in_map_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Panel / Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(top: BorderSide(color: AppTheme.borderDark.withOpacity(0.5))),
            ),
            child: SafeArea(
              top: false,
              child: _isDownloading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Downloading Offline Pack...',
                              style: TextStyle(color: AppTheme.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${((_downloadProgress?.percent ?? 0.0) * 100).toInt()}%',
                              style: const TextStyle(color: AppTheme.primaryGreenLight, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _downloadProgress?.percent ?? 0.0,
                            minHeight: 8,
                            backgroundColor: AppTheme.bgDark,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreenLight),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_downloadProgress?.downloadedTiles ?? 0} / ${_downloadProgress?.totalTiles ?? 0} tiles',
                              style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
                            ),
                            Text(
                              '${_downloadProgress?.downloadedMB ?? 0.0} MB saved',
                              style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPro ? AppTheme.primaryGreen : AppTheme.cardDark,
                          foregroundColor: isPro ? Colors.white : AppTheme.accentAmber,
                          side: isPro ? null : BorderSide(color: AppTheme.accentAmber.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(isPro ? Icons.download_rounded : Icons.lock_outline_rounded, size: 20),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isPackReady ? 'Re-Download / Update Territory Pack' : 'Download Offline Pack (${estimate['estimatedMB']} MB)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (!isPro) ...[
                              const SizedBox(width: 8),
                              const ProBadge(
                                fontSize: 8.5,
                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              ),
                            ],
                          ],
                        ),
                        onPressed: _startDownload,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
