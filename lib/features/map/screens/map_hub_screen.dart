import 'dart:async';
import 'dart:math' as math;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/app_toast.dart';
import '../services/campus_proximity_service.dart';
import '../services/offline_map_service.dart';
import '../services/offline_router_service.dart';
import 'offline_map_pack_screen.dart';

class MapHubScreen extends ConsumerStatefulWidget {
  final String? initialTargetRoomCode;
  final LatLng? initialTargetCoordinate;

  const MapHubScreen({
    super.key,
    this.initialTargetRoomCode,
    this.initialTargetCoordinate,
  });

  @override
  ConsumerState<MapHubScreen> createState() => _MapHubScreenState();
}

class _MapHubScreenState extends ConsumerState<MapHubScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Distance _distCalc = const Distance();

  LatLng _currentCenter = OfflineMapService.defaultCampusCenter;
  LatLng? _userGpsLocation;
  double _userHeading = 0.0;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<CampusPin>>? _pinsSub;
  List<CampusPin> _activeCampusPins = [];

  // Moving Pin Mode
  CampusPin? _movingPin;

  // Mock Location & Simulation Mode
  bool _isMockGpsActive = false;
  bool _isMockTapPlacementMode = false;

  // Waypoint & Route Navigation (GTA V Style)
  LatLng? _activeWaypoint;
  String? _activeWaypointTitle;
  List<LatLng> _routePolyline = [];
  bool _isCalculatingRoute = false;
  CommuteMode _selectedCommuteMode = CommuteMode.walk;
  RouteStrategy _selectedRouteStrategy = RouteStrategy.fastest;
  bool _isRouteHudExpanded = false;

  // Offline tile provider base directory
  String? _offlineTileDir;
  bool _isOfflineReady = false;
  LatLngBounds? _savedBounds;
  LatLng? _savedCampusCenter;

  // Animation controller for pulsing player blip
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initMapSystem();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pinsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initMapSystem() async {
    final isReady = await OfflineMapService.isOfflineReady();
    final tileDir = await OfflineMapService.getTileStorageDirectory();
    final savedBounds = await OfflineMapService.getSavedBounds();
    final customCampusCenter = await OfflineMapService.getUserCampusCenter();

    if (mounted) {
      setState(() {
        _isOfflineReady = isReady;
        _offlineTileDir = tileDir;
        _savedBounds = savedBounds;
        _savedCampusCenter = customCampusCenter;
        if (customCampusCenter != null) {
          _currentCenter = customCampusCenter;
        } else if (savedBounds != null) {
          _currentCenter = savedBounds.center;
        }
      });
    }

    final db = ref.read(databaseProvider);
    final profile = await db.getActiveProfile();
    if (profile != null) {
      _pinsSub = db.watchCampusPins(profile.id).listen((pins) {
        if (mounted) {
          setState(() => _activeCampusPins = pins);
        }
      });
    }

    _startHardwareGpsStream();

    // Check if initial room or coordinate was passed from Dashboard
    if (widget.initialTargetCoordinate != null) {
      _setWaypoint(widget.initialTargetCoordinate!, title: widget.initialTargetRoomCode ?? 'Classroom');
    } else if (widget.initialTargetRoomCode != null) {
      _lookupAndNavigateToRoom(widget.initialTargetRoomCode!);
    }
  }

  Future<void> _lookupAndNavigateToRoom(String roomCode) async {
    final db = ref.read(databaseProvider);
    final profile = await db.getActiveProfile();
    if (profile == null) return;

    final pin = await db.getCampusPinForRoom(profile.id, roomCode);
    if (pin != null) {
      final target = LatLng(pin.latitude, pin.longitude);
      _mapController.move(target, 16.5);
      _setWaypoint(target, title: '${pin.roomCode} • ${pin.buildingName ?? "Campus Building"}');
    } else {
      if (mounted) {
        AppToast.showWarning(
          context,
          'Room "$roomCode" is not calibrated yet. Long-press on campus to drop a pin.',
          icon: Icons.meeting_room_outlined,
        );
      }
    }
  }

  Future<void> _startHardwareGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Read current location once
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _userGpsLocation = LatLng(initialPos.latitude, initialPos.longitude);
          _userHeading = initialPos.heading;
        });
      }

      // Stream live satellite updates (works with zero mobile data)
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // meters
        ),
      ).listen((pos) async {
        if (_isMockGpsActive) return; // Do not overwrite user-defined mock location
        if (mounted) {
          final newLoc = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _userGpsLocation = newLoc;
            _userHeading = pos.heading;
          });

          // Proximity geofence arrival detection for commuters (Pro Feature)
          final isPro = ref.read(isProProvider);
          if (isPro) {
            final arrival = await CampusProximityService.checkProximity(
              userLocation: newLoc,
              pins: _activeCampusPins,
              activeWaypoint: _activeWaypoint,
              activeWaypointTitle: _activeWaypointTitle,
            );

            if (arrival != null && mounted) {
              AppToast.showArrival(
                context,
                '${arrival.title} • ${arrival.message}',
                icon: Icons.location_on_rounded,
                duration: const Duration(seconds: 4),
              );
            }
          }

          // Dynamic route update as student moves
          if (_activeWaypoint != null && !_isCalculatingRoute) {
            _recalculateRoute();
          }
        }
      });
    } catch (e) {
      AppLogService.info(AppLogService.catApp, 'Hardware GPS stream init: $e');
    }
  }

  void _setWaypoint(LatLng point, {String? title}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeWaypoint = point;
      _activeWaypointTitle = title ?? 'Custom Waypoint';
    });
    _recalculateRoute();
  }

  void _clearWaypoint() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeWaypoint = null;
      _activeWaypointTitle = null;
      _routePolyline = [];
    });
  }

  Future<void> _recalculateRoute() async {
    if (_activeWaypoint == null) return;
    final origin = _userGpsLocation ?? _currentCenter;

    setState(() => _isCalculatingRoute = true);

    try {
      final path = await OfflineRouterService.findRoute(
        origin,
        _activeWaypoint!,
        mode: _selectedCommuteMode,
        strategy: _selectedRouteStrategy,
      );
      if (mounted) {
        setState(() {
          _routePolyline = path;
          _isCalculatingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCalculatingRoute = false);
      }
    }
  }

  Future<void> _setMockLocation(LatLng point) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _userGpsLocation = point;
      _isMockGpsActive = true;
    });

    // Check proximity arrival alert immediately (Pro Feature)
    final isPro = ref.read(isProProvider);
    ProximityArrivalEvent? arrival;
    if (isPro) {
      arrival = await CampusProximityService.checkProximity(
        userLocation: point,
        pins: _activeCampusPins,
        activeWaypoint: _activeWaypoint,
        activeWaypointTitle: _activeWaypointTitle,
      );
    }

    if (arrival != null && mounted) {
      AppToast.showArrival(
        context,
        '${arrival.title} • ${arrival.message}',
        icon: Icons.location_on_rounded,
        duration: const Duration(seconds: 4),
      );
    } else if (mounted) {
      AppToast.showMockLocation(
        context,
        'Simulated Location: (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})',
        icon: Icons.gps_fixed_rounded,
      );
    }

    if (_activeWaypoint != null) {
      _recalculateRoute();
    }
  }

  Future<void> _resetToHardwareGps() async {
    setState(() {
      _isMockGpsActive = false;
      _isMockTapPlacementMode = false;
    });
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _userGpsLocation = LatLng(pos.latitude, pos.longitude);
          _userHeading = pos.heading;
        });
        AppToast.showInfo(
          context,
          'Real Hardware GPS restored.',
          icon: Icons.my_location_rounded,
        );
        if (_activeWaypoint != null) {
          _recalculateRoute();
        }
      }
    } catch (_) {}
  }

  LatLng? _getCalculatedCampusCenter() {
    if (_activeCampusPins.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (final p in _activeCampusPins) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      return LatLng(sumLat / _activeCampusPins.length, sumLng / _activeCampusPins.length);
    }
    if (_savedCampusCenter != null) {
      return _savedCampusCenter;
    }
    if (_savedBounds != null) {
      return _savedBounds!.center;
    }
    return null;
  }

  String? _getCampusCenterDescription() {
    if (_activeCampusPins.isNotEmpty) {
      return 'Calculated from ${_activeCampusPins.length} mapped campus buildings';
    }
    if (_savedCampusCenter != null) {
      return 'Custom calibrated campus location';
    }
    if (_savedBounds != null) {
      return 'Offline map package territory center';
    }
    return null;
  }

  void _openMockLocationSheet() {
    HapticFeedback.lightImpact();
    final campusCenter = _getCalculatedCampusCenter();
    final campusLabel = _getCampusCenterDescription();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MockLocationSheet(
        isMockActive: _isMockGpsActive,
        currentLocation: _userGpsLocation,
        campusCenter: campusCenter,
        campusCenterLabel: campusLabel,
        campusPins: _activeCampusPins,
        onEnableTapMode: () {
          Navigator.of(ctx).pop();
          setState(() => _isMockTapPlacementMode = true);
          AppToast.showMockLocation(
            context,
            'Mock Location Mode: Tap anywhere on the map to set your location.',
            icon: Icons.touch_app_rounded,
          );
        },
        onTeleport: (point, name) {
          Navigator.of(ctx).pop();
          _mapController.move(point, 16.5);
          _setMockLocation(point);
        },
        onSetCampusCenterHere: (point) async {
          await OfflineMapService.saveUserCampusCenter(point);
          setState(() => _savedCampusCenter = point);
          if (mounted) {
            AppToast.showSuccess(
              context,
              'Campus center calibrated to (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})',
              icon: Icons.school_rounded,
            );
          }
        },
        onResetGps: () {
          Navigator.of(ctx).pop();
          _resetToHardwareGps();
        },
      ),
    );
  }

  void _centerOnUser() {
    HapticFeedback.lightImpact();
    if (_userGpsLocation != null) {
      _mapController.move(_userGpsLocation!, 16.0);
    } else {
      AppToast.showInfo(
        context,
        'Awaiting GPS satellite fix...',
        icon: Icons.gps_fixed_rounded,
      );
    }
  }

  void _centerOnCampus() {
    HapticFeedback.lightImpact();
    final campus = _getCalculatedCampusCenter() ?? OfflineMapService.defaultCampusCenter;
    _mapController.move(campus, 16.5);
    AppToast.showInfo(
      context,
      'Moved view to Campus.',
      icon: Icons.school_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  void _openCampusCalibrationSheet(LatLng point) async {
    HapticFeedback.heavyImpact();
    final db = ref.read(databaseProvider);
    final profile = await db.getActiveProfile();
    if (profile == null) return;

    final distinctRooms = await db.getDistinctScheduleRoomCodes(profile.id);
    final existingPins = await db.getCampusPins(profile.id);
    final mappedRooms = existingPins.map((p) => p.roomCode).toSet();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CampusCalibrationModal(
        coordinate: point,
        distinctRooms: distinctRooms,
        existingPins: existingPins,
        mappedRooms: mappedRooms,
        profileId: profile.id,
        db: db,
        onPinSaved: (pin) {
          _mapController.move(point, 16.5);
          _setWaypoint(point, title: '${pin.roomCode} • ${pin.buildingName ?? "Campus Building"}');
        },
      ),
    );
  }

  void _showCampusPinActionsSheet(CampusPin pin) {
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final coord = LatLng(pin.latitude, pin.longitude);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryGreenLight.withOpacity(0.4)),
                      ),
                      child: Text(
                        pin.roomCode,
                        style: const TextStyle(
                          color: AppTheme.primaryGreenLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pin.buildingName ?? 'Campus Building',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pin.latitude.toStringAsFixed(5)}, ${pin.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMutedDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Navigate Here
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_walk_rounded, color: Color(0xFFC084FC), size: 20),
                  ),
                  title: const Text('Navigate Here', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Draw commute & travel route to this room', style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _setWaypoint(coord, title: '${pin.roomCode} • ${pin.buildingName ?? "Campus Building"}');
                  },
                ),
                const Divider(color: AppTheme.borderDark, height: 16),

                // 2. Move / Recalibrate Pin Location
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.touch_app_rounded, color: AppTheme.accentCyan, size: 20),
                  ),
                  title: const Text('Move / Reposition Pin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tap anywhere on the map to relocate this pin', style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _movingPin = pin);
                    AppToast.showInfo(
                      context,
                      'Tap anywhere on the map to reposition "${pin.roomCode}".',
                      icon: Icons.touch_app_rounded,
                      duration: const Duration(seconds: 4),
                    );
                  },
                ),
                const Divider(color: AppTheme.borderDark, height: 16),

                // 3. Edit Room / Building Details
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppTheme.primaryGreenLight, size: 20),
                  ),
                  title: const Text('Edit Pin Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Rename building or change room code', style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openEditPinDialog(pin);
                  },
                ),
                const Divider(color: AppTheme.borderDark, height: 16),

                // 4. Delete Pin
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRose, size: 20),
                  ),
                  title: const Text('Remove Pin', style: TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Delete this campus room coordinate', style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: AppTheme.cardDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Remove Pin?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Are you sure you want to remove the pinned location for "${pin.roomCode}" (${pin.buildingName ?? 'Campus Building'})?',
                          style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(false),
                            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentRose,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await db.deleteCampusPin(pin.id);
                      if (_activeWaypoint != null &&
                          _activeWaypoint!.latitude == pin.latitude &&
                          _activeWaypoint!.longitude == pin.longitude) {
                        _clearWaypoint();
                      }
                      if (mounted) {
                        AppToast.showSuccess(
                          context,
                          'Pin "${pin.roomCode}" removed.',
                          icon: Icons.delete_outline_rounded,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditPinDialog(CampusPin pin) {
    final db = ref.read(databaseProvider);
    final roomController = TextEditingController(text: pin.roomCode);
    final buildingController = TextEditingController(text: pin.buildingName ?? '');

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Campus Pin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomController,
              decoration: InputDecoration(
                labelText: 'Room Code (e.g. CS 101 / LAB 204)',
                filled: true,
                fillColor: AppTheme.bgDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: buildingController,
              decoration: InputDecoration(
                labelText: 'Building Name (e.g. IT Wing)',
                filled: true,
                fillColor: AppTheme.bgDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newRoom = roomController.text.trim();
              final newBuilding = buildingController.text.trim();
              if (newRoom.isEmpty) return;

              final companion = pin.toCompanion(true).copyWith(
                roomCode: drift.Value(newRoom),
                buildingName: drift.Value(newBuilding.isNotEmpty ? newBuilding : null),
                updatedAt: drift.Value(DateTime.now()),
              );

              await db.insertOrUpdateCampusPin(companion);
              if (mounted) {
                Navigator.of(dCtx).pop();
                AppToast.showSuccess(
                  context,
                  'Pin details updated for "$newRoom".',
                  icon: Icons.check_circle_outline_rounded,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final profileAsync = ref.watch(activeProfileStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // FlutterMap Tile Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) async {
                if (_movingPin != null) {
                  final pinToMove = _movingPin!;
                  final companion = pinToMove.toCompanion(true).copyWith(
                    latitude: drift.Value(point.latitude),
                    longitude: drift.Value(point.longitude),
                    updatedAt: drift.Value(DateTime.now()),
                  );
                  await db.insertOrUpdateCampusPin(companion);
                  HapticFeedback.mediumImpact();
                  if (mounted) {
                    setState(() => _movingPin = null);
                    AppToast.showSuccess(
                      context,
                      'Room pin "${pinToMove.roomCode}" moved to new location!',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  }
                  return;
                }
                if (_isMockTapPlacementMode) {
                  _setMockLocation(point);
                  return;
                }
                // Single tap drops waypoint
                _setWaypoint(point);
              },
              onLongPress: (tapPosition, point) {
                // Long press opens Campus Calibration POI Binder
                _openCampusCalibrationSheet(point);
              },
            ),
            children: [
              // Tile Layer
              if (_offlineTileDir != null)
                TileLayer(
                  tileProvider: OfflineFileTileProvider(baseDirectory: _offlineTileDir!),
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.classbase.sembase',
                ),

              // GTA V Style Route Polyline Layer with Commute Mode Styling
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer glow / shadow polyline
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 8.0,
                      color: _getRouteGlowColor(),
                    ),
                    // Inner sharp route polyline
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 4.5,
                      color: _getRoutePrimaryColor(),
                      borderColor: Colors.white.withOpacity(0.8),
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),

              // Stream of Saved Campus Building POI Markers
              profileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  return StreamBuilder<List<CampusPin>>(
                    stream: db.watchCampusPins(profile.id),
                    builder: (context, snapshot) {
                      final pins = snapshot.data ?? [];
                      return MarkerLayer(
                        markers: [
                          ...pins.map((pin) {
                            final coord = LatLng(pin.latitude, pin.longitude);
                            return Marker(
                              point: coord,
                              width: 90,
                              height: 60,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _showCampusPinActionsSheet(pin);
                                },
                                child: _buildCampusBuildingMarker(pin),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Waypoint Marker (GTA V Style)
              if (_activeWaypoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _activeWaypoint!,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onDoubleTap: _clearWaypoint,
                        child: _buildWaypointMarker(),
                      ),
                    ),
                  ],
                ),

              // Live GPS Player Blip Marker
              if (_userGpsLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userGpsLocation!,
                      width: 44,
                      height: 44,
                      child: _buildPlayerGpsBlip(),
                    ),
                  ],
                ),
            ],
          ),

          // Top Repositioning HUD Banner when in Move Pin mode
          if (_movingPin != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentCyan, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentCyan.withOpacity(0.25), blurRadius: 12),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppTheme.accentCyan, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Repositioning ${_movingPin!.roomCode}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Text(
                            'Tap anywhere on the map to place new location',
                            style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _movingPin = null);
                      },
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // Top Mock Location Mode Banner
          if (_isMockTapPlacementMode && _movingPin == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.25), blurRadius: 12),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, color: Color(0xFF14B8A6), size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mock Location Placement Active',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Tap anywhere on the map to place your position',
                            style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isMockTapPlacementMode = false);
                      },
                      child: const Text('Done', style: TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // Top GTA V Style Navigation HUD Banner
          if (_activeWaypoint != null && _movingPin == null && !_isMockTapPlacementMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: _buildNavigationHud(),
            ),

          // Top Left Status Badges
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 16,
            child: _activeWaypoint == null && !_isMockTapPlacementMode && _movingPin == null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isOfflineReady ? AppTheme.primaryGreen.withOpacity(0.4) : AppTheme.accentAmber.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isOfflineReady ? Icons.offline_pin_rounded : Icons.cloud_outlined,
                              size: 14,
                              color: _isOfflineReady ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isOfflineReady ? '100% OFFLINE MAP' : 'ONLINE PREVIEW',
                              style: TextStyle(
                                color: _isOfflineReady ? AppTheme.primaryGreenLight : AppTheme.accentAmber,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isMockGpsActive) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openMockLocationSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF14B8A6), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'MOCK GPS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Top Right Settings & Calibration Action
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _activeWaypoint == null && !_isMockTapPlacementMode && _movingPin == null
                ? FloatingActionButton.small(
                    heroTag: 'map_settings',
                    backgroundColor: AppTheme.cardDark,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.tune_rounded, size: 18),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OfflineMapPackScreen()),
                      ).then((_) => _initMapSystem());
                    },
                  )
                : const SizedBox.shrink(),
          ),

          // Floating Action Buttons (Center GPS, Mock Location, Calibration Helper)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mock Location Simulator FAB
                FloatingActionButton.small(
                  heroTag: 'mock_gps_fab',
                  backgroundColor: _isMockGpsActive ? const Color(0xFF0D9488) : AppTheme.cardDark,
                  foregroundColor: Colors.white,
                  tooltip: 'Mock Location Simulator',
                  onPressed: _openMockLocationSheet,
                  child: Icon(
                    _isMockGpsActive ? Icons.edit_location_alt_rounded : Icons.developer_mode_rounded,
                    size: 18,
                    color: _isMockGpsActive ? Colors.white : AppTheme.accentCyan,
                  ),
                ),
                const SizedBox(height: 10),
                // Move to Campus View FAB
                FloatingActionButton.small(
                  heroTag: 'campus_view_fab',
                  backgroundColor: AppTheme.cardDark,
                  foregroundColor: AppTheme.primaryGreenLight,
                  tooltip: 'Move to Campus View',
                  onPressed: _centerOnCampus,
                  child: const Icon(Icons.school_rounded, size: 18),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'gps_locate',
                  backgroundColor: AppTheme.cardDark,
                  foregroundColor: _userGpsLocation != null ? AppTheme.accentCyan : AppTheme.textMutedDark,
                  tooltip: 'Center on My GPS',
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'add_poi',
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    AppToast.showInfo(
                      context,
                      'Long-press anywhere on campus building to pin a schedule room code.',
                      icon: Icons.add_location_alt_rounded,
                    );
                  },
                  child: const Icon(Icons.add_location_alt_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusBuildingMarker(CampusPin pin) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.primaryGreenLight.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
            ],
          ),
          child: Text(
            pin.roomCode,
            style: const TextStyle(
              color: AppTheme.primaryGreenLight,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: AppTheme.primaryGreenLight,
          size: 24,
        ),
      ],
    );
  }

  Widget _buildWaypointMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF9333EA).withOpacity(0.3),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC084FC),
                boxShadow: [
                  BoxShadow(color: Color(0xFF9333EA), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerGpsBlip() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 36 * _pulseAnimation.value,
              height: 36 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_isMockGpsActive ? const Color(0xFF0D9488) : AppTheme.accentCyan).withOpacity(0.25),
              ),
            );
          },
        ),
        // Direction arrow & center blip
        Transform.rotate(
          angle: (_userHeading * math.pi / 180.0),
          child: Icon(
            Icons.navigation_rounded,
            color: _isMockGpsActive ? const Color(0xFF14B8A6) : AppTheme.accentCyan,
            size: 26,
          ),
        ),
        if (_isMockGpsActive)
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'MOCK',
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Color _getRoutePrimaryColor() {
    switch (_selectedCommuteMode) {
      case CommuteMode.walk:
        return const Color(0xFFC084FC); // GTA Purple
      case CommuteMode.motor:
        return const Color(0xFF10B981); // Emerald Green
      case CommuteMode.jeepney:
        return const Color(0xFFF59E0B); // Amber / Jeepney Gold
      case CommuteMode.car:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color _getRouteGlowColor() {
    switch (_selectedCommuteMode) {
      case CommuteMode.walk:
        return const Color(0xFF9333EA).withOpacity(0.4);
      case CommuteMode.motor:
        return const Color(0xFF059669).withOpacity(0.4);
      case CommuteMode.jeepney:
        return const Color(0xFFD97706).withOpacity(0.4);
      case CommuteMode.car:
        return const Color(0xFF2563EB).withOpacity(0.4);
    }
  }

  IconData _getCommuteModeIcon(CommuteMode mode) {
    switch (mode) {
      case CommuteMode.walk:
        return Icons.directions_walk_rounded;
      case CommuteMode.motor:
        return Icons.two_wheeler_rounded;
      case CommuteMode.jeepney:
        return Icons.airport_shuttle_rounded;
      case CommuteMode.car:
        return Icons.directions_car_rounded;
    }
  }

  Widget _buildNavigationHud() {
    final origin = _userGpsLocation ?? _currentCenter;
    final distMeters = _distCalc.as(LengthUnit.Meter, origin, _activeWaypoint!);
    final commute = OfflineRouterService.calculateCommute(
      distanceMeters: distMeters,
      mode: _selectedCommuteMode,
      strategy: _selectedRouteStrategy,
    );

    final modeColor = _getRoutePrimaryColor();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: modeColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: modeColor.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getCommuteModeIcon(_selectedCommuteMode), color: modeColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _activeWaypointTitle ?? 'Target Waypoint',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${commute.formattedDistance} • ~${commute.formattedTime}',
                              style: TextStyle(
                                color: modeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: '(${commute.mode.displayName})',
                              style: const TextStyle(
                                color: AppTheme.textSecondaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Toggle expand options
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    _isRouteHudExpanded ? Icons.expand_less_rounded : Icons.tune_rounded,
                    color: _isRouteHudExpanded ? modeColor : AppTheme.textMutedDark,
                    size: 20,
                  ),
                  tooltip: _isRouteHudExpanded ? 'Collapse options' : 'Choose vehicle & route',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isRouteHudExpanded = !_isRouteHudExpanded);
                  },
                ),
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMutedDark, size: 20),
                  tooltip: 'Clear Route',
                  onPressed: _clearWaypoint,
                ),
              ],
            ),
          ),

          // Collapsible vehicle mode selector and route corridor choices
          if (_isRouteHudExpanded) const Divider(color: AppTheme.borderDark, height: 1),
          if (_isRouteHudExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCommuteModeSelector(modeColor),
                  const SizedBox(height: 12),
                  _buildRouteStrategySelector(modeColor),
                  const SizedBox(height: 10),
                  _buildCommuteSummary(modeColor, commute),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommuteModeSelector(Color modeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'COMMUTE MODE / VEHICLE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.textMutedDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final mode in CommuteMode.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (_selectedCommuteMode != mode) {
                        HapticFeedback.mediumImpact();
                        setState(() => _selectedCommuteMode = mode);
                        _recalculateRoute();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: mode == _selectedCommuteMode ? modeColor.withOpacity(0.2) : AppTheme.bgDark.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: mode == _selectedCommuteMode ? modeColor : AppTheme.borderDark,
                          width: mode == _selectedCommuteMode ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCommuteModeIcon(mode),
                            size: 14,
                            color: mode == _selectedCommuteMode ? modeColor : AppTheme.textSecondaryDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              color: mode == _selectedCommuteMode ? Colors.white : AppTheme.textSecondaryDark,
                              fontSize: 11,
                              fontWeight: mode == _selectedCommuteMode ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStrategySelector(Color modeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'ROUTE STRATEGY & CORRIDOR',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.textMutedDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final strategy in RouteStrategy.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (_selectedRouteStrategy != strategy) {
                        HapticFeedback.mediumImpact();
                        setState(() => _selectedRouteStrategy = strategy);
                        _recalculateRoute();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: strategy == _selectedRouteStrategy ? modeColor.withOpacity(0.2) : AppTheme.bgDark.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: strategy == _selectedRouteStrategy ? modeColor : AppTheme.borderDark,
                          width: strategy == _selectedRouteStrategy ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            strategy == RouteStrategy.fastest
                                ? Icons.bolt_rounded
                                : (strategy == RouteStrategy.highway ? Icons.alt_route_rounded : Icons.turn_right_rounded),
                            size: 13,
                            color: strategy == _selectedRouteStrategy ? modeColor : AppTheme.textSecondaryDark,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            strategy.shortLabel,
                            style: TextStyle(
                              color: strategy == _selectedRouteStrategy ? Colors.white : AppTheme.textSecondaryDark,
                              fontSize: 11,
                              fontWeight: strategy == _selectedRouteStrategy ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommuteSummary(Color modeColor, CommuteCalculationResult commute) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgDark.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 13, color: modeColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              commute.summary,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppTheme.textSecondaryDark,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (commute.fareEstimate != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryGreenLight.withOpacity(0.4)),
              ),
              child: Text(
                commute.fareEstimate!,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppTheme.primaryGreenLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Campus Calibration Bottom Sheet
class _CampusCalibrationModal extends StatefulWidget {
  final LatLng coordinate;
  final List<String> distinctRooms;
  final List<CampusPin> existingPins;
  final Set<String> mappedRooms;
  final String profileId;
  final AppDatabase db;
  final ValueChanged<CampusPin> onPinSaved;

  const _CampusCalibrationModal({
    required this.coordinate,
    required this.distinctRooms,
    required this.existingPins,
    required this.mappedRooms,
    required this.profileId,
    required this.db,
    required this.onPinSaved,
  });

  @override
  State<_CampusCalibrationModal> createState() => _CampusCalibrationModalState();
}

class _CampusCalibrationModalState extends State<_CampusCalibrationModal> {
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _customRoomController = TextEditingController();
  String? _selectedRoomCode;

  @override
  void initState() {
    super.initState();
    // Default to first unmapped room if available, or first distinct room
    final unmapped = widget.distinctRooms.where((r) => !widget.mappedRooms.contains(r)).toList();
    if (unmapped.isNotEmpty) {
      _selectedRoomCode = unmapped.first;
    } else if (widget.distinctRooms.isNotEmpty) {
      _selectedRoomCode = widget.distinctRooms.first;
      _prefillForRoom(_selectedRoomCode);
    }
  }

  void _prefillForRoom(String? room) {
    if (room == null || room == 'CUSTOM') return;
    for (final p in widget.existingPins) {
      if (p.roomCode == room) {
        if (p.buildingName != null && p.buildingName!.isNotEmpty) {
          _buildingController.text = p.buildingName!;
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _customRoomController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final finalRoom = _selectedRoomCode == 'CUSTOM'
        ? _customRoomController.text.trim()
        : _selectedRoomCode?.trim();

    if (finalRoom == null || finalRoom.isEmpty) {
      AppToast.showWarning(context, 'Please select or enter a room code');
      return;
    }

    // Check if an existing pin exists for this room
    CampusPin? existingPin;
    for (final p in widget.existingPins) {
      if (p.roomCode.toLowerCase() == finalRoom.toLowerCase()) {
        existingPin = p;
        break;
      }
    }

    final id = existingPin?.id ?? const Uuid().v4();
    final companion = CampusPinsCompanion.insert(
      id: id,
      profileId: widget.profileId,
      roomCode: finalRoom,
      buildingName: drift.Value(_buildingController.text.trim().isNotEmpty ? _buildingController.text.trim() : null),
      latitude: widget.coordinate.latitude,
      longitude: widget.coordinate.longitude,
      pinColor: const drift.Value('#10B981'),
    );

    await widget.db.insertOrUpdateCampusPin(companion);
    final savedPin = await widget.db.getCampusPinForRoom(widget.profileId, finalRoom);

    if (mounted) {
      Navigator.of(context).pop();
      if (savedPin != null) {
        widget.onPinSaved(savedPin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyMapped = _selectedRoomCode != null &&
        _selectedRoomCode != 'CUSTOM' &&
        widget.mappedRooms.contains(_selectedRoomCode);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_location_alt_rounded, color: AppTheme.primaryGreenLight, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Calibrate Campus Building POI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Bind this building coordinate to a room code from your imported class schedule:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
            ),
            const SizedBox(height: 12),

            // Room code selector chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.distinctRooms.map((room) {
                  final isMapped = widget.mappedRooms.contains(room);
                  final isSelected = _selectedRoomCode == room;
                  return ChoiceChip(
                    label: Text('$room ${isMapped ? "✓" : ""}'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: isMapped ? AppTheme.bgDark.withOpacity(0.6) : AppTheme.cardDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRoomCode = room;
                          _prefillForRoom(room);
                        });
                      }
                    },
                  );
                }),
                ChoiceChip(
                  label: const Text('+ Custom Room'),
                  selected: _selectedRoomCode == 'CUSTOM',
                  selectedColor: AppTheme.accentCyan,
                  backgroundColor: AppTheme.cardDark,
                  labelStyle: TextStyle(
                    color: _selectedRoomCode == 'CUSTOM' ? Colors.white : AppTheme.textSecondaryDark,
                    fontSize: 11.5,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRoomCode = 'CUSTOM');
                  },
                ),
              ],
            ),

            if (isAlreadyMapped) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.accentCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Room "$_selectedRoomCode" is already mapped. Saving will move its location to here.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_selectedRoomCode == 'CUSTOM') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customRoomController,
                decoration: InputDecoration(
                  labelText: 'Custom Room Code (e.g. LAB 204)',
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                  filled: true,
                  fillColor: AppTheme.bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _buildingController,
              decoration: InputDecoration(
                labelText: 'Building Name (Optional, e.g. IT Building / Main Wing)',
                prefixIcon: const Icon(Icons.business_rounded),
                filled: true,
                fillColor: AppTheme.bgDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isAlreadyMapped ? 'Update / Recalibrate Room Pin' : 'Save Campus Building Pin',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _savePin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom modal sheet for Mock Location & Campus Simulation
class _MockLocationSheet extends StatefulWidget {
  final bool isMockActive;
  final LatLng? currentLocation;
  final LatLng? campusCenter;
  final String? campusCenterLabel;
  final List<CampusPin> campusPins;
  final VoidCallback onEnableTapMode;
  final Function(LatLng point, String name) onTeleport;
  final Function(LatLng point) onSetCampusCenterHere;
  final VoidCallback onResetGps;

  const _MockLocationSheet({
    required this.isMockActive,
    required this.currentLocation,
    required this.campusCenter,
    required this.campusCenterLabel,
    required this.campusPins,
    required this.onEnableTapMode,
    required this.onTeleport,
    required this.onSetCampusCenterHere,
    required this.onResetGps,
  });

  @override
  State<_MockLocationSheet> createState() => _MockLocationSheetState();
}

class _MockLocationSheetState extends State<_MockLocationSheet> {
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    final cur = widget.currentLocation ?? widget.campusCenter ?? OfflineMapService.defaultCampusCenter;
    _latController = TextEditingController(text: cur.latitude.toStringAsFixed(6));
    _lngController = TextEditingController(text: cur.longitude.toStringAsFixed(6));
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = math.max(MediaQuery.of(context).padding.bottom, 16.0);

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomInset + bottomPadding + 16,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.bgDarkElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF14B8A6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mock GPS & Simulation Hub',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.isMockActive
                              ? 'Simulated GPS is currently ACTIVE'
                              : 'Simulate live location without walking',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isMockActive ? const Color(0xFF14B8A6) : AppTheme.textSecondaryDark,
                            fontWeight: widget.isMockActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isMockActive)
                    TextButton.icon(
                      onPressed: widget.onResetGps,
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.accentRose),
                      label: const Text('Reset GPS', style: TextStyle(color: AppTheme.accentRose, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode 1: Interactive Tap on Map
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: const Color(0xFF0D9488).withOpacity(0.4)),
                ),
                tileColor: AppTheme.cardDark,
                leading: const Icon(Icons.touch_app_rounded, color: Color(0xFF14B8A6)),
                title: const Text('Interactive Map Tap Placement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: const Text('Tap anywhere directly on the map to place your position', style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMutedDark),
                onTap: widget.onEnableTapMode,
              ),
              const SizedBox(height: 12),

              // Mode 2: Teleport to Campus Center
              if (widget.campusCenter != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.borderDark.withOpacity(0.4)),
                  ),
                  tileColor: AppTheme.cardDark,
                  leading: const Icon(Icons.school_rounded, color: AppTheme.accentCyan),
                  title: const Text('Teleport to Campus Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    widget.campusCenterLabel ?? 'Lat: ${widget.campusCenter!.latitude.toStringAsFixed(4)}, Lng: ${widget.campusCenter!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.near_me_rounded, size: 18, color: AppTheme.accentCyan),
                  onTap: () => widget.onTeleport(widget.campusCenter!, 'Campus Center'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school_outlined, color: AppTheme.accentAmber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Campus Location Not Calibrated Yet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You haven\'t pinned any classroom buildings or saved a campus location yet. Drop a pin on campus or set your current position as campus center.',
                        style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11.5, height: 1.3),
                      ),
                      if (widget.currentLocation != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.bgDarkElevated,
                              foregroundColor: AppTheme.accentCyan,
                              side: const BorderSide(color: AppTheme.accentCyan, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                            label: const Text('Set Current Location as Campus Center', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              widget.onSetCampusCenterHere(widget.currentLocation!);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              if (widget.campusPins.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'QUICK TELEPORT TO ENROLLED ROOMS',
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.campusPins.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final p = widget.campusPins[idx];
                      return ActionChip(
                        avatar: const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF8B5CF6)),
                        backgroundColor: AppTheme.cardDark,
                        side: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                        label: Text(
                          '${p.roomCode}${p.buildingName != null ? " (${p.buildingName})" : ""}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          widget.onTeleport(LatLng(p.latitude, p.longitude), p.roomCode);
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 18),
              const Text(
                'CUSTOM GPS COORDINATES',
                style: TextStyle(
                  color: AppTheme.textMutedDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        filled: true,
                        fillColor: AppTheme.bgDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        filled: true,
                        fillColor: AppTheme.bgDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('Teleport to Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  onPressed: () {
                    final lat = double.tryParse(_latController.text.trim());
                    final lng = double.tryParse(_lngController.text.trim());
                    if (lat != null && lng != null) {
                      widget.onTeleport(LatLng(lat, lng), 'Custom Coordinates');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

