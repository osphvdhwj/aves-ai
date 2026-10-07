import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

/// On-device NSFW classification.
///
/// The Dart side is complete; the native side (Kotlin) is a stub until
/// someone implements it with a real model. The bridge contract is:
///
///   method channel: `deckers.thibault/aves/nsfw`
///   method:         `classify`
///   args:           { 'entry': <platform entry map> }
///   returns:        Map with:
///                     'available': bool   — model loaded & ready
///                     'score':     double — 0.0 (safe) .. 1.0 (NSFW)
///                     'labels':    List<String> — e.g. ['nudity', 'suggestive']
///
/// Implementation notes for the native side:
///   1. Ship a TFLite model under `android/app/src/main/assets/models/`.
///   2. Load once, cache the interpreter.
///   3. Decode a 224x224 thumbnail of the entry (ImageProvider already
///      exists in `deckers.thibault.aves.model.provider`).
///   4. Run inference, return the score.
///
/// Until the native side returns `available: true`, this service resolves
/// to [NsfwResult.unknown] and callers must treat NSFW status as unknown.
class NsfwService {
  static const _platform = AvesMethodChannel('deckers.thibault/aves/nsfw');

  Future<NsfwResult> classify(AvesEntry entry) async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('classify', {
        'entry': entry.toPlatformEntryMap(),
      });
      if (result == null) return const NsfwResult.unknown();
      final map = result.cast<String, dynamic>();
      final available = map['available'] == true;
      if (!available) return const NsfwResult.unknown();
      final score = (map['score'] as num?)?.toDouble();
      final labels = (map['labels'] as List?)?.cast<String>() ?? const <String>[];
      if (score == null) return const NsfwResult.unknown();
      return NsfwResult(available: true, score: score, labels: labels);
    } on MissingPluginException {
      return const NsfwResult.unknown();
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
      return NsfwResult(available: false, score: null, labels: const [], error: e.message);
    }
  }
}

class NsfwResult {
  /// Whether the classifier could run. `false` when the native side is a
  /// stub or the model failed to load.
  final bool available;

  /// 0.0 = safe, 1.0 = NSFW. `null` when unavailable.
  final double? score;

  /// Free-form labels the classifier attached, e.g. ['nudity'].
  final List<String> labels;

  final String? error;

  const NsfwResult({
    required this.available,
    required this.score,
    this.labels = const [],
    this.error,
  });

  const NsfwResult.unknown() : available = false, score = null, labels = const [], error = null;

  /// Suggested tag when score is high enough. Callers decide the threshold.
  String? tagFor({double threshold = 0.75}) {
    if (!available || score == null) return null;
    if (score! < threshold) return null;
    if (labels.isNotEmpty) return labels.first;
    return 'nsfw';
  }

  /// Confidence bucket for UI — 'safe', 'uncertain', 'nsfw', 'unknown'.
  String get bucket {
    if (!available || score == null) return 'unknown';
    if (score! < 0.3) return 'safe';
    if (score! < 0.75) return 'uncertain';
    return 'nsfw';
  }
}

final nsfwService = NsfwService();
