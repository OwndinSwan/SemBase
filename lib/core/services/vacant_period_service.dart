import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to manage and persist user edits, deletions, and custom labels for vacant schedule periods
class VacantPeriodService {
  static const _storage = FlutterSecureStorage();
  static const _keyHidden = 'sembase_vacant_hidden_blocks';
  static const _keyLabels = 'sembase_vacant_custom_labels';
  static const _keyRanges = 'sembase_vacant_custom_ranges';

  static Set<String> cachedHidden = {};
  static Map<String, String> cachedLabels = {};
  static Map<String, Map<String, int>> cachedRanges = {};

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static Future<void> init() async {
    cachedHidden = await getHiddenBlocks();
    cachedLabels = await getCustomLabels();
    cachedRanges = await getCustomRanges();
    changeNotifier.value++;
  }

  static Future<Set<String>> getHiddenBlocks() async {
    try {
      final raw = await _storage.read(key: _keyHidden);
      if (raw == null || raw.isEmpty) return {};
      final list = jsonDecode(raw) as List;
      final set = list.map((e) => e.toString()).toSet();
      cachedHidden = set;
      return set;
    } catch (_) {
      return {};
    }
  }

  static Future<void> hideBlock(String blockId) async {
    final hidden = await getHiddenBlocks();
    hidden.add(blockId);
    cachedHidden = hidden;
    await _storage.write(key: _keyHidden, value: jsonEncode(hidden.toList()));
    changeNotifier.value++;
  }

  static Future<void> unhideBlock(String blockId) async {
    final hidden = await getHiddenBlocks();
    hidden.remove(blockId);
    cachedHidden = hidden;
    await _storage.write(key: _keyHidden, value: jsonEncode(hidden.toList()));
    changeNotifier.value++;
  }

  static Future<Map<String, String>> getCustomLabels() async {
    try {
      final raw = await _storage.read(key: _keyLabels);
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = map.map((k, v) => MapEntry(k, v.toString()));
      cachedLabels = result;
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> setCustomLabel(String blockId, String label) async {
    final labels = await getCustomLabels();
    if (label.trim().isEmpty) {
      labels.remove(blockId);
    } else {
      labels[blockId] = label.trim();
    }
    cachedLabels = labels;
    await _storage.write(key: _keyLabels, value: jsonEncode(labels));
    changeNotifier.value++;
  }

  static Future<Map<String, Map<String, int>>> getCustomRanges() async {
    try {
      final raw = await _storage.read(key: _keyRanges);
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = map.map((k, v) {
        final inner = v as Map<String, dynamic>;
        return MapEntry(k, {
          'start': inner['start'] as int,
          'end': inner['end'] as int,
        });
      });
      cachedRanges = result;
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> setCustomRange(String blockId, int startMin, int endMin) async {
    final ranges = await getCustomRanges();
    ranges[blockId] = {'start': startMin, 'end': endMin};
    cachedRanges = ranges;
    await _storage.write(key: _keyRanges, value: jsonEncode(ranges));
    changeNotifier.value++;
  }

  static Future<void> resetBlock(String blockId) async {
    final hidden = await getHiddenBlocks();
    hidden.remove(blockId);
    cachedHidden = hidden;
    await _storage.write(key: _keyHidden, value: jsonEncode(hidden.toList()));

    final labels = await getCustomLabels();
    labels.remove(blockId);
    cachedLabels = labels;
    await _storage.write(key: _keyLabels, value: jsonEncode(labels));

    final ranges = await getCustomRanges();
    ranges.remove(blockId);
    cachedRanges = ranges;
    await _storage.write(key: _keyRanges, value: jsonEncode(ranges));

    changeNotifier.value++;
  }
}
