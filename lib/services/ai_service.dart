import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';
import 'package:aves/model/entry/entry.dart';

class AiService {
  static const _platform = AvesMethodChannel('deckers.thibault/aves/ai');

  // Session cache: the companion's health does not change during a
  // session, so one probe per app launch is enough. Use forceRefresh
  // after installing/updating the companion.
  Future<AiHealth>? _healthFuture;

  Future<AiHealth> health({bool forceRefresh = false}) {
    if (forceRefresh || _healthFuture == null) {
      _healthFuture = _probeHealth();
    }
    return _healthFuture!;
  }

  /// Convenience check. Same caching as [health].
  Future<bool> hasCapability(String capability) async {
    final h = await health();
    return h.connected && h.has(capability);
  }

  Future<AiHealth> _probeHealth() async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('health');
      if (result == null) return const AiHealth(installed: false, connected: false);
      final map = result.cast<String, dynamic>();
      return AiHealth(
        installed: map['installed'] == true,
        connected: map['connected'] == true,
        apiVersion: map['apiVersion'] as int?,
        capabilities: (map['capabilities'] as List?)?.cast<String>() ?? const [],
        error: map['error'] as String?,
        companionPackage: map['companionPackage'] as String?,
      );
    } on PlatformException catch (e, s) {
      await reportService.recordError(e, s);
      return AiHealth(installed: false, connected: false, error: e.message);
    }
  }

  Future<AiChatReply> chat(
    String text, {
    List<int> entryIds = const [],
    List<Map<String, dynamic>> entries = const [],
  }) async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('chat', {
        'text': text,
        'entryIds': entryIds,
        'entries': entries,
      });
      if (result == null) return const AiChatReply(text: '', error: 'no reply');
      final map = result.cast<String, dynamic>();
      final code = map['errorCode'];
      return AiChatReply(
        text: (map['text'] as String?) ?? '',
        entryIds: (map['entryIds'] as List?)?.cast<int>() ?? const [],
        error: map['errorMessage'] as String?,
        errorCode: code is int ? code : (code is num ? code.toInt() : null),
        hint: map['hint'] as String?,
        groupSizes: (map['groupSizes'] as List?)?.cast<int>() ?? const [],
        extra: map['extra'] as String?,
      );
    } on PlatformException catch (e, s) {
      await reportService.recordError(e, s);
      return AiChatReply(text: '', error: e.message ?? e.code);
    }
  }

  /// Builds the `entries` payload the companion expects. Every media
  /// operation needs `path` or `uri`; `id` and `contentId` let the
  /// companion echo results back without a second lookup.
  static List<Map<String, dynamic>> entriesPayload(Iterable<AvesEntry> entries) {
    return entries.map((e) => <String, dynamic>{
      'id': e.id,
      'contentId': e.contentId,
      'uri': e.uri,
      'path': e.path,
      'mimeType': e.mimeType,
    }).toList();
  }

  /// Sends one personalization training event to the companion's
  /// auto-training engine (find_like / find_dislike / nsfw_safe /
  /// nsfw_explicit). Fire and forget: failures are logged, never thrown.
  Future<void> feedback({
    required String type,
    int? entryId,
    String? query,
    double? score,
  }) async {
    try {
      await _platform.invokeMethod('feedback', {
        'type': type,
        if (entryId != null) 'entryIds': [entryId],
        if (query != null && query.isNotEmpty) 'query': query,
        if (score != null) 'score': score,
      });
    } on PlatformException catch (e, s) {
      await reportService.recordError(e, s);
    } catch (e, s) {
      await reportService.recordError(e, s);
    }
  }

  /// Batch-embeds [entries] into the companion's CLIP vector index in
  /// chunks, so each AIDL call stays well under the companion's budget.
  /// Returns the total embedded/skipped counts. Throws on companion
  /// failure so the caller can stop and report.
  Future<({int embedded, int skipped})> indexBuild(
    List<AvesEntry> entries, {
    int chunkSize = 25,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    var embedded = 0;
    var skipped = 0;
    final total = entries.length;
    for (var i = 0; i < total; i += chunkSize) {
      if (isCancelled?.call() ?? false) break;
      final end = i + chunkSize < total ? i + chunkSize : total;
      final chunk = entries.sublist(i, end);
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('indexBuild', {
        'entries': entriesPayload(chunk),
      });
      final map = result?.cast<String, dynamic>() ?? const <String, dynamic>{};
      embedded += (map['embedded'] as num?)?.toInt() ?? 0;
      skipped += (map['skipped'] as num?)?.toInt() ?? 0;
      onProgress?.call(end, total);
    }
    return (embedded: embedded, skipped: skipped);
  }

  /// Number of vectors in the companion's index; -1 when unreachable.
  Future<int> indexCount() async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('indexCount');
      return (result?['count'] as num?)?.toInt() ?? -1;
    } on PlatformException {
      return -1;
    }
  }
}

class AiHealth {
  final bool installed;
  final bool connected;
  final int? apiVersion;
  final List<String> capabilities;
  final String? error;

  /// Which package provided the answering service. Kotlin enumerates a
  /// preference list of candidate companions; this reports which one
  /// won. Null when nothing was found.
  final String? companionPackage;

  const AiHealth({
    required this.installed,
    required this.connected,
    this.apiVersion,
    this.capabilities = const [],
    this.error,
    this.companionPackage,
  });

  /// Whether the companion advertised the given capability id, e.g.
  /// `'nsfw'`, `'ocr'`, `'person'`, `'objects'`, `'translate'`.
  bool has(String capability) => capabilities.contains(capability);

  @override
  String toString() => 'AiHealth(installed: $installed, connected: $connected, apiVersion: $apiVersion, capabilities: $capabilities, error: $error, companionPackage: $companionPackage)';
}

class AiChatReply {
  final String text;
  final List<int> entryIds;
  final String? error;

  /// Numeric code from the companion's error contract (0 OK, 1
  /// UNSUPPORTED, 2 MODEL_MISSING, 3 OOM, 4 PERMISSION, 5 INTERNAL,
  /// 6 CANCELLED). Null on success or when the call never reached the
  /// companion.
  final int? errorCode;

  /// Companion hint attached to empty results, e.g. `index_empty` when
  /// the vector index needs building before /find can match anything.
  final String? hint;

  /// Cluster sizes parallel to [entryIds] (/dup, /faces): the flat id
  /// list split at these sizes yields one list per group. Empty when the
  /// command has no grouping or the companion predates groupSizes.
  final List<int> groupSizes;

  /// Command-specific JSON payload, e.g. the /objects * histogram.
  final String? extra;

  const AiChatReply({
    required this.text,
    this.entryIds = const [],
    this.error,
    this.errorCode,
    this.hint,
    this.groupSizes = const [],
    this.extra,
  });

  bool get isModelMissing => errorCode == 2;
  bool get isUnsupported => errorCode == 1;
  bool get isIndexEmpty => hint?.startsWith('index_empty') ?? false;

  /// Splits [entryIds] into groups of [groupSizes]. Returns one flat
  /// group when sizes are missing or do not sum to the id count.
  List<List<int>> get groupedEntryIds {
    final sizes = groupSizes;
    if (sizes.isEmpty || sizes.fold<int>(0, (a, b) => a + b) != entryIds.length) {
      return entryIds.isEmpty ? const [] : [entryIds];
    }
    final out = <List<int>>[];
    var offset = 0;
    for (final size in sizes) {
      out.add(entryIds.sublist(offset, offset + size));
      offset += size;
    }
    return out;
  }
}

final aiService = AiService();
