import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';
import 'package:aves/services/ai_service.dart';

/// Per-entry Google Photos backup status.
///
/// Aves does not talk to Google's cloud directly. On devices where the
/// AVES+ Tools companion is installed (and rooted), Tools reads Google
/// Photos' own local database and reports whether each MediaStore id has
/// been backed up. This service is the Dart-side caller; when the
/// companion is not installed, every lookup resolves to
/// [BackupStatus.unknown] and the info page stays quiet.
///
/// Channel: `deckers.thibault/aves/ai`
/// Method:  `gphotosBackupStatus`
/// Args:    { "mediaStoreIds": [int, ...] }
/// Returns: { "statuses": { "<id>": "uploaded" | "not_uploaded" | "unknown" } }
///
/// Routes through the same Kotlin AiHandler that carries `chat`,
/// which binds the AVESPlusTools companion over AIDL and asks it to
/// read Google Photos' own SQLite DBs. The ids sent are MediaStore
/// `_id` values, which Aves carries as `AvesEntry.contentId` — that
/// is what GP's `local_media.media_store_id` column stores.
class GPhotosBackupService {
  static const _platform = AvesMethodChannel('deckers.thibault/aves/ai');

  // Session cache. Google Photos only changes a given entry's backup
  // state on its own schedule, so a few minutes of staleness is fine.
  static const _cacheTtl = Duration(minutes: 5);
  final Map<int, _CacheEntry> _cache = {};
  final Set<int> _inFlight = {};

  /// Bulk lookup. Returns a map keyed by MediaStore id. Entries not
  /// present in the reply are treated as unknown by [statusOf].
  ///
  /// Results are cached for [_cacheTtl]. The companion is queried only
  /// for ids that are missing or stale.
  Future<Map<int, BackupStatus>> lookup(Iterable<int> mediaStoreIds, {bool forceRefresh = false}) async {
    final ids = mediaStoreIds.toSet().toList();
    if (ids.isEmpty) return const {};

    final now = DateTime.now();
    final out = <int, BackupStatus>{};
    final toFetch = <int>[];

    for (final id in ids) {
      final hit = _cache[id];
      if (!forceRefresh && hit != null && now.difference(hit.at) < _cacheTtl) {
        out[id] = hit.status;
      } else if (!_inFlight.contains(id)) {
        toFetch.add(id);
      }
    }

    if (toFetch.isEmpty) return out;

    _inFlight.addAll(toFetch);
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('gphotosBackupStatus', {
        'mediaStoreIds': toFetch,
      });
      final raw = result?['statuses'];
      final fetched = <int, BackupStatus>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id == null) return;
          fetched[id] = BackupStatus.fromName(v?.toString());
        });
      }
      for (final id in toFetch) {
        final status = fetched[id] ?? BackupStatus.unknown;
        _cache[id] = _CacheEntry(status, now);
        out[id] = status;
      }
    } on MissingPluginException {
      // Companion not installed — cache unknown so we stop retrying.
      for (final id in toFetch) {
        _cache[id] = _CacheEntry(BackupStatus.unknown, now);
      }
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      for (final id in toFetch) {
        _cache[id] = _CacheEntry(BackupStatus.unknown, now);
      }
    } finally {
      _inFlight.removeAll(toFetch);
    }
    return out;
  }

  /// Convenience single-entry lookup. Resolves to
  /// [BackupStatus.unknown] when the companion is absent.
  Future<BackupStatus> statusOf(AvesEntry entry) async {
    final id = _mediaStoreIdOf(entry);
    if (id == null) return BackupStatus.unknown;
    final map = await lookup([id]);
    return map[id] ?? BackupStatus.unknown;
  }

  /// Drop cached values so the next lookup re-queries the companion.
  void invalidate() => _cache.clear();

  /// True when the companion's `provider.ping` succeeded at least once
  /// this session. Cached so the UI can gate itself without an IPC hop.
  bool? _available;
  bool get isAvailable => _available ?? false;

  Future<bool> probe() async {
    try {
      // provider.ping now lives on the AIDL bridge as part of the health
      // probe; delegate to that to avoid a second channel.
      final h = await aiService.health();
      _available = h.connected;
    } on MissingPluginException {
      _available = false;
    } on PlatformException {
      _available = false;
    }
    return _available!;
  }

  /// The entry's MediaStore `_id`.
  ///
  /// Not `AvesEntry.id` (that is Aves's own DB row id). `contentId`
  /// is populated from the MediaStore cursor and is the value Google
  /// Photos' `local_media.media_store_id` column refers to.
  int? _mediaStoreIdOf(AvesEntry entry) => entry.contentId;
}

enum BackupStatus {
  uploaded,
  notUploaded,
  unknown;

  static BackupStatus fromName(String? name) {
    switch (name) {
      case 'uploaded':
        return BackupStatus.uploaded;
      case 'not_uploaded':
        return BackupStatus.notUploaded;
      case 'unknown':
      default:
        return BackupStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case BackupStatus.uploaded:
        return 'Backed up to Google Photos';
      case BackupStatus.notUploaded:
        return 'Not backed up to Google Photos';
      case BackupStatus.unknown:
        return 'Google Photos backup status unavailable';
    }
  }
}

final gphotosBackupService = GPhotosBackupService();

class _CacheEntry {
  final BackupStatus status;
  final DateTime at;

  const _CacheEntry(this.status, this.at);
}

