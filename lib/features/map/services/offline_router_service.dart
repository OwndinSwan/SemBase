import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/logging/app_log_service.dart';

class RoadNode {
  final int id;
  final double lat;
  final double lon;
  final List<int> neighbors;

  RoadNode({
    required this.id,
    required this.lat,
    required this.lon,
    required this.neighbors,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'neighbors': neighbors,
      };

  factory RoadNode.fromJson(Map<String, dynamic> json) => RoadNode(
        id: json['id'] as int,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        neighbors: (json['neighbors'] as List<dynamic>).map((e) => e as int).toList(),
      );
}

enum CommuteMode {
  walk,
  motor,
  jeepney,
  car;

  String get displayName {
    switch (this) {
      case CommuteMode.walk:
        return 'Walk';
      case CommuteMode.motor:
        return 'Angkas / Motor';
      case CommuteMode.jeepney:
        return 'Jeepney / PUV';
      case CommuteMode.car:
        return 'Private Car';
    }
  }

  String get subLabel {
    switch (this) {
      case CommuteMode.walk:
        return 'On-Foot / Campus Walk';
      case CommuteMode.motor:
        return 'MoveIt / Habal-Habal / Motor';
      case CommuteMode.jeepney:
        return 'Jeep / Bus / Public Transit';
      case CommuteMode.car:
        return 'Car / Grab / Taxi';
    }
  }
}

enum RouteStrategy {
  fastest,
  highway,
  shortcut;

  String get displayName {
    switch (this) {
      case RouteStrategy.fastest:
        return 'Fastest Route';
      case RouteStrategy.highway:
        return 'Main Highway (e.g. Aguinaldo)';
      case RouteStrategy.shortcut:
        return 'Shortcuts & Inner Alleys';
    }
  }

  String get shortLabel {
    switch (this) {
      case RouteStrategy.fastest:
        return 'Fastest';
      case RouteStrategy.highway:
        return 'Main Highway';
      case RouteStrategy.shortcut:
        return 'Shortcuts';
    }
  }
}

class CommuteCalculationResult {
  final int minutes;
  final String formattedTime;
  final double distanceMeters;
  final String formattedDistance;
  final String summary;
  final String? fareEstimate;
  final CommuteMode mode;
  final RouteStrategy strategy;

  const CommuteCalculationResult({
    required this.minutes,
    required this.formattedTime,
    required this.distanceMeters,
    required this.formattedDistance,
    required this.summary,
    this.fareEstimate,
    required this.mode,
    required this.strategy,
  });
}

class OfflineRouterService {
  static const Distance _distCalc = Distance();
  static List<RoadNode>? _cachedGraph;
  static final Map<String, List<LatLng>> _routeMemoryCache = {};

  /// Calculates dynamic commute travel time, formatted distance, and fare estimates
  static CommuteCalculationResult calculateCommute({
    required double distanceMeters,
    required CommuteMode mode,
    RouteStrategy strategy = RouteStrategy.fastest,
  }) {
    double effectiveDist = distanceMeters;
    double speedMetersPerMin = 83.33; // Default walk ~5 km/h
    int bufferMinutes = 0;
    String? fare;
    String summary = '';

    switch (mode) {
      case CommuteMode.walk:
        speedMetersPerMin = 83.33; // 5 km/h
        bufferMinutes = 0;
        fare = 'Free';
        if (strategy == RouteStrategy.shortcut) {
          effectiveDist = distanceMeters * 0.94;
          summary = 'Footpath / Campus Shortcuts';
        } else if (strategy == RouteStrategy.highway) {
          effectiveDist = distanceMeters * 1.05;
          summary = 'Sidewalk via Main Avenue';
        } else {
          summary = 'Standard Walking Route';
        }
        break;

      case CommuteMode.motor:
        // Angkas / MoveIt / Habal-Habal / Motor (~35 km/h)
        if (strategy == RouteStrategy.highway) {
          speedMetersPerMin = 633.3; // ~38 km/h on open highway
          effectiveDist = distanceMeters * 1.05;
          bufferMinutes = 1;
          summary = 'Via Highway Corridors';
        } else if (strategy == RouteStrategy.shortcut) {
          speedMetersPerMin = 500.0; // ~30 km/h maneuvering alleys
          effectiveDist = distanceMeters * 0.88; // avoids big highway loops
          bufferMinutes = 1;
          summary = 'Via Alleys & Inner Street Shortcuts';
        } else {
          speedMetersPerMin = 583.3; // ~35 km/h
          bufferMinutes = 1;
          summary = 'Angkas / Habal-Habal Route';
        }

        // Philippine Motorcycle taxi base fare (~P50 for first 2km, +P10/km)
        final distKm = effectiveDist / 1000.0;
        if (distKm <= 2.0) {
          fare = '₱50 - ₱60';
        } else {
          final est = (50 + (distKm - 2.0) * 12).round();
          fare = '₱$est - ₱${est + 15}';
        }
        break;

      case CommuteMode.jeepney:
        // Jeepney / Bus / PUV (~18 km/h on transit corridors with frequent stops)
        if (strategy == RouteStrategy.highway) {
          speedMetersPerMin = 333.3; // ~20 km/h on public highway
          effectiveDist = distanceMeters * 1.08;
          bufferMinutes = 4; // Passenger boarding / waiting buffer
          summary = 'Via Main Public Highway (Jeep Corridors)';
        } else if (strategy == RouteStrategy.shortcut) {
          speedMetersPerMin = 250.0; // ~15 km/h on tricycle/feeder routes
          effectiveDist = distanceMeters * 0.95;
          bufferMinutes = 3;
          summary = 'Via Local Feeder / Tricycle Route';
        } else {
          speedMetersPerMin = 300.0; // ~18 km/h
          bufferMinutes = 4;
          summary = 'Jeepney / PUV Transit Corridor';
        }

        // Philippine student / regular jeepney fare
        final distKm = effectiveDist / 1000.0;
        if (distKm <= 4.0) {
          fare = '₱13 - ₱15 (Student: ₱13)';
        } else {
          final est = (15 + (distKm - 4.0) * 1.8).round();
          final studentEst = (13 + (distKm - 4.0) * 1.5).round();
          fare = '₱$est - ₱${est + 3} (Student: ₱$studentEst)';
        }
        break;

      case CommuteMode.car:
        // Private Car / Grab / Taxi (~26 km/h with traffic)
        if (strategy == RouteStrategy.highway) {
          speedMetersPerMin = 500.0; // ~30 km/h
          effectiveDist = distanceMeters * 1.08;
          bufferMinutes = 4; // Traffic light delays
          summary = 'Via Main Arterial Highways';
        } else if (strategy == RouteStrategy.shortcut) {
          speedMetersPerMin = 366.7; // ~22 km/h in residential areas
          effectiveDist = distanceMeters * 0.92;
          bufferMinutes = 2;
          summary = 'Via Residential / Inner Street Bypass';
        } else {
          speedMetersPerMin = 450.0; // ~27 km/h
          bufferMinutes = 3;
          summary = 'Private Vehicle / Grab Route';
        }

        // Philippine Grab / Taxi base estimate
        final distKm = effectiveDist / 1000.0;
        final baseGrab = (60 + distKm * 15).round();
        fare = 'Grab ~₱$baseGrab - ₱${baseGrab + 30}';
        break;
    }

    final rawMinutes = (effectiveDist / speedMetersPerMin).round() + bufferMinutes;
    final minutes = math.max(1, rawMinutes);

    String formattedTime;
    if (minutes < 60) {
      formattedTime = '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remMin = minutes % 60;
      formattedTime = remMin > 0 ? '$hours hr $remMin min' : '$hours hr';
    }

    final formattedDistance = effectiveDist >= 1000
        ? '${(effectiveDist / 1000).toStringAsFixed(1)} km'
        : '${effectiveDist.toInt()} m';

    return CommuteCalculationResult(
      minutes: minutes,
      formattedTime: formattedTime,
      distanceMeters: effectiveDist,
      formattedDistance: formattedDistance,
      summary: summary,
      fareEstimate: fare,
      mode: mode,
      strategy: strategy,
    );
  }

  static Future<String> getGraphFilePath() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'offline_routing_graph.json');
  }

  /// Downloads highway, roads, and campus pedestrian networks inside the bounding box
  static Future<void> downloadAndSaveRoadNetwork(LatLngBounds bounds) async {
    final mirrors = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
    ];

    final s = bounds.south;
    final w = bounds.west;
    final n = bounds.north;
    final e = bounds.east;

    final overpassQuery = """
[out:json][timeout:25];
(
  way["highway"~"motorway|trunk|primary|secondary|tertiary|residential|unclassified|service|living_street|pedestrian|footway|path|steps|track"]($s,$w,$n,$e);
);
out body;
>;
out skel qt;
""";

    for (final mirrorUrl in mirrors) {
      try {
        final url = Uri.parse(mirrorUrl);
        final res = await http.post(
          url,
          body: {'data': overpassQuery},
          headers: {'User-Agent': 'SemBase/1.0.8 (Offline Campus Road Router)'},
        ).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final elements = data['elements'] as List<dynamic>? ?? [];

          final Map<int, LatLng> rawNodes = {};
          final Map<int, Set<int>> adjacency = {};

          for (final el in elements) {
            if (el['type'] == 'node') {
              final id = el['id'] as int;
              final lat = (el['lat'] as num).toDouble();
              final lon = (el['lon'] as num).toDouble();
              rawNodes[id] = LatLng(lat, lon);
            }
          }

          for (final el in elements) {
            if (el['type'] == 'way') {
              final nodes = (el['nodes'] as List<dynamic>?)?.map((e) => e as int).toList();
              if (nodes != null && nodes.length > 1) {
                for (int i = 0; i < nodes.length - 1; i++) {
                  final u = nodes[i];
                  final v = nodes[i + 1];
                  adjacency.putIfAbsent(u, () => <int>{}).add(v);
                  adjacency.putIfAbsent(v, () => <int>{}).add(u);
                }
              }
            }
          }

          final List<RoadNode> roadNodes = [];
          for (final entry in adjacency.entries) {
            final id = entry.key;
            final coord = rawNodes[id];
            if (coord != null) {
              roadNodes.add(RoadNode(
                id: id,
                lat: coord.latitude,
                lon: coord.longitude,
                neighbors: entry.value.toList(),
              ));
            }
          }

          if (roadNodes.isNotEmpty) {
            final filePath = await getGraphFilePath();
            final file = File(filePath);
            await file.writeAsString(jsonEncode(roadNodes.map((n) => n.toJson()).toList()));
            _cachedGraph = roadNodes;

            AppLogService.success(
              AppLogService.catApp,
              'Saved offline road network graph: ${roadNodes.length} nodes',
            );
            return; // Successfully saved
          }
        }
      } catch (e) {
        debugPrint('Mirror $mirrorUrl attempt: $e');
      }
    }
  }

  /// Loads the road graph from local storage
  static Future<List<RoadNode>> loadGraph() async {
    if (_cachedGraph != null) return _cachedGraph!;
    try {
      final filePath = await getGraphFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = jsonDecode(content) as List<dynamic>;
        _cachedGraph = jsonList.map((e) => RoadNode.fromJson(e as Map<String, dynamic>)).toList();
        return _cachedGraph!;
      }
    } catch (e) {
      debugPrint('Could not load local road graph: $e');
    }
    return [];
  }

  /// Calculates the shortest road route polyline from origin to destination hugging real streets and curves
  static Future<List<LatLng>> findRoute(
    LatLng origin,
    LatLng destination, {
    CommuteMode mode = CommuteMode.walk,
    RouteStrategy strategy = RouteStrategy.fastest,
  }) async {
    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}->${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}:${mode.name}:${strategy.name}';
    
    // Check in-memory route cache
    if (_routeMemoryCache.containsKey(cacheKey)) {
      return _routeMemoryCache[cacheKey]!;
    }

    // 1. Try high-precision road geometry routing via OSRM (driving/walking roads)
    try {
      final osrmProfile = (mode == CommuteMode.walk) ? 'foot' : 'driving';
      final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/$osrmProfile/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );
      final res = await http.get(osrmUrl, headers: {
        'User-Agent': 'SemBase/1.0.8 (Campus Navigation Engine)',
      }).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? [];
        if (routes.isNotEmpty) {
          final geometry = routes.first['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>? ?? [];
          if (coordinates.length >= 2) {
            final List<LatLng> osrmPoints = coordinates.map((c) {
              final lon = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lon);
            }).toList();

            _routeMemoryCache[cacheKey] = osrmPoints;
            return osrmPoints;
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // 2. Offline A* Search on local Overpass road network graph
    final graph = await loadGraph();
    if (graph.isNotEmpty && graph.length >= 5) {
      RoadNode? startNode;
      RoadNode? endNode;
      double minStartDist = double.infinity;
      double minEndDist = double.infinity;

      final nodeMap = <int, RoadNode>{};
      for (final node in graph) {
        nodeMap[node.id] = node;
        final nodeCoord = LatLng(node.lat, node.lon);

        final dStart = _distCalc.as(LengthUnit.Meter, origin, nodeCoord);
        if (dStart < minStartDist) {
          minStartDist = dStart;
          startNode = node;
        }

        final dEnd = _distCalc.as(LengthUnit.Meter, destination, nodeCoord);
        if (dEnd < minEndDist) {
          minEndDist = dEnd;
          endNode = node;
        }
      }

      if (startNode != null && endNode != null && minStartDist < 2000 && minEndDist < 2000) {
        final cameFrom = <int, int>{};
        final openSet = <int>{startNode.id};
        final gScore = <int, double>{startNode.id: 0.0};
        final fScore = <int, double>{
          startNode.id: _distCalc.as(LengthUnit.Meter, LatLng(startNode.lat, startNode.lon), LatLng(endNode.lat, endNode.lon)),
        };

        while (openSet.isNotEmpty) {
          int currentId = openSet.first;
          double lowestF = fScore[currentId] ?? double.infinity;
          for (final id in openSet) {
            final f = fScore[id] ?? double.infinity;
            if (f < lowestF) {
              lowestF = f;
              currentId = id;
            }
          }

          if (currentId == endNode.id) {
            final List<LatLng> path = [destination];
            int curr = endNode.id;
            while (cameFrom.containsKey(curr)) {
              final n = nodeMap[curr];
              if (n != null) {
                path.add(LatLng(n.lat, n.lon));
              }
              curr = cameFrom[curr]!;
            }
            final startN = nodeMap[startNode.id];
            if (startN != null) {
              path.add(LatLng(startN.lat, startN.lon));
            }
            path.add(origin);
            final result = path.reversed.toList();
            _routeMemoryCache[cacheKey] = result;
            return result;
          }

          openSet.remove(currentId);
          final currentNode = nodeMap[currentId];
          if (currentNode == null) continue;
          final currentCoord = LatLng(currentNode.lat, currentNode.lon);
          final currentG = gScore[currentId] ?? double.infinity;

          for (final neighborId in currentNode.neighbors) {
            final neighborNode = nodeMap[neighborId];
            if (neighborNode == null) continue;

            final neighborCoord = LatLng(neighborNode.lat, neighborNode.lon);
            final stepDist = _distCalc.as(LengthUnit.Meter, currentCoord, neighborCoord);
            final tentativeG = currentG + stepDist;

            if (tentativeG < (gScore[neighborId] ?? double.infinity)) {
              cameFrom[neighborId] = currentId;
              gScore[neighborId] = tentativeG;
              final h = _distCalc.as(LengthUnit.Meter, neighborCoord, LatLng(endNode.lat, endNode.lon));
              fScore[neighborId] = tentativeG + h;
              openSet.add(neighborId);
            }
          }
        }
      }
    }

    // 3. Clean fallback polyline connecting straight if completely disconnected
    final direct = [origin, destination];
    _routeMemoryCache[cacheKey] = direct;
    return direct;
  }

  static Future<void> clearRoadNetwork() async {
    _cachedGraph = null;
    _routeMemoryCache.clear();
    try {
      final filePath = await getGraphFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
