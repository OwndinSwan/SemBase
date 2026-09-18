import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/database/app_database.dart';
import '../../../core/logging/app_log_service.dart';
import '../../../core/notifications/alarm_notification_service.dart';

class ProximityArrivalEvent {
  final String title;
  final String message;
  final double distanceMeters;
  final String targetId;

  const ProximityArrivalEvent({
    required this.title,
    required this.message,
    required this.distanceMeters,
    required this.targetId,
  });
}

class CampusProximityService {
  static final Distance _distance = const Distance();
  static final Map<String, DateTime> _lastNotified = {};
  static const Duration cooldown = Duration(minutes: 30);

  /// Clears in-memory cooldown state (useful for testing or resetting)
  static void resetCooldowns() {
    _lastNotified.clear();
  }

  /// Checks user location against active waypoint and all pinned campus buildings
  static Future<ProximityArrivalEvent?> checkProximity({
    required LatLng userLocation,
    required List<CampusPin> pins,
    LatLng? activeWaypoint,
    String? activeWaypointTitle,
  }) async {
    if (!AlarmNotificationService.cachedProximityAlerts) return null;

    final radius = AlarmNotificationService.cachedProximityRadiusMeters;
    final now = DateTime.now();

    // 1. Check Active Waypoint first
    if (activeWaypoint != null) {
      final dist = _distance.as(LengthUnit.Meter, userLocation, activeWaypoint);
      if (dist <= radius) {
        final key = 'waypoint_${activeWaypoint.latitude.toStringAsFixed(4)}_${activeWaypoint.longitude.toStringAsFixed(4)}';
        final last = _lastNotified[key];
        if (last == null || now.difference(last) > cooldown) {
          _lastNotified[key] = now;
          final title = '📍 Arrived at ${activeWaypointTitle ?? "Waypoint"}';
          final body = 'You are within ${dist.round()}m of your target destination.';
          
          await HapticFeedback.heavyImpact();
          await AlarmNotificationService.showProximityArrivalNotification(
            title: title,
            body: body,
            payload: 'waypoint_arrival',
          );

          AppLogService.success(
            AppLogService.catAlarm,
            'Waypoint arrival triggered',
            details: '$title (${dist.round()}m)',
          );

          return ProximityArrivalEvent(
            title: title,
            message: body,
            distanceMeters: dist,
            targetId: key,
          );
        }
      }
    }

    // 2. Check all campus pins
    for (final pin in pins) {
      final pinCoord = LatLng(pin.latitude, pin.longitude);
      final dist = _distance.as(LengthUnit.Meter, userLocation, pinCoord);
      if (dist <= radius) {
        final key = 'pin_${pin.id}';
        final last = _lastNotified[key];
        if (last == null || now.difference(last) > cooldown) {
          _lastNotified[key] = now;
          final buildingStr = pin.buildingName != null && pin.buildingName!.isNotEmpty
              ? ' (${pin.buildingName})'
              : '';
          final title = '📍 Arrived at ${pin.roomCode}$buildingStr';
          final body = 'You are within ${dist.round()}m of your pinned classroom.';

          await HapticFeedback.heavyImpact();
          await AlarmNotificationService.showProximityArrivalNotification(
            title: title,
            body: body,
            payload: 'room_${pin.roomCode}',
          );

          AppLogService.success(
            AppLogService.catAlarm,
            'Campus pin arrival triggered',
            details: '$title (${dist.round()}m)',
          );

          return ProximityArrivalEvent(
            title: title,
            message: body,
            distanceMeters: dist,
            targetId: key,
          );
        }
      }
    }

    return null;
  }
}
