import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

/// Per-entry Google Photos backup status.
///
/// Aves does not talk to Google's cloud directly. On devices where the
/// AVES+ Tools companion is installed (and rooted), Tools reads Google
/// Photos' own local database and reports whether each MediaStore id has
/// been backed up. This service is the Dart-side caller; when the
/// companion is not installed, every lookup resolves to
/// [BackupStatus.unknown] and the info page stays quiet.
///
/// Channel: `com.avesplus.tools/bridge`
/// Method:  `gphotos.backup_status`
/// Args:    { "mediaStoreIds": [int, ...] }
/// Returns: { "statuses": { "<id>": "uploaded" | "not_uploaded" | "unknown" } }
///
/// The ids sent are MediaStore `_id` values, which Aves carries as
/// `AvesEntry.contentId`. Google Photos' own `local_media` table keys
/// its rows by the same MediaStore `_id`.
class GPhotosBackupService {
  static const _platform = AvesMethodChannel('com.avesplus.tools/bridge');

  /// Bulk lookup. Returns a map keyed by MediaStore id. Entries not
  /// present in the reply are treated as unknown by [statusOf].
  Future<Map<int, BackupStatus>> lookup(Iterable<int> mediaStoreIds) async {
    final ids = mediaStoreIds.toList();
    if (ids.isEmpty) return const {};
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('gphotos.backup_status', {
        'mediaStoreIds': ids,
      });
      if (result == null) return const {};
      final raw = result['statuses'];
      if (raw is! Map) return const {};
      final out = <int, BackupStatus>{};
      raw.forEach((k, v) {
        final id = int.tryParse(k.toString());
        if (id == null) return;
        out[id] = BackupStatus.fromName(v?.toString());
      });
      return out;
    } on MissingPluginException {
      // Companion not installed — silently no-op.
      return const {};
    } on PlatformException catch (e, stack) {
      // Log and degrade; never throw into the UI.
      await reportService.recordError(e, stack);
      return const {};
    }
  }

  /// Convenience single-entry lookup. Resolves to
  /// [BackupStatus.unknown] when the companion is absent.
  Future<BackupStatus> statusOf(AvesEntry entry) async {
    final id = _mediaStoreIdOf(entry);
    if (id == null) return BackupStatus.unknown;
    final map = await lookup([id]);
    return map[id] ?? BackupStatus.unknown;
  }

  /// True when the companion's `provider.ping` succeeded at least once
  /// this session. Cached so the UI can gate itself without an IPC hop.
  bool? _available;
  bool get isAvailable => _available ?? false;

  Future<bool> probe() async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('provider.ping');
      _available = result != null;
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
