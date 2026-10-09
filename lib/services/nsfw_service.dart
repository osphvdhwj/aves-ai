import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';

/// NSFW classification routed through the shared AI companion
/// (`deckers.thibault/aves/ai`) using the `@nsfw` command.
///
/// Aves never talks to a dedicated classifier channel; the companion
/// advertises `nsfw` in its `AiHealth.capabilities` when it can score.
/// If it cannot, this service resolves to [NsfwResult.unknown] and no
/// NSFW tag is proposed.
///
/// The companion is expected to reply with a single line containing the
/// score, e.g. `0.87` or `nsfw:0.87:nudity,suggestive`. The parser below
/// accepts both forms plus a plain JSON object in `AiChatReply.text`.
class NsfwService {
  Future<NsfwResult> classify(AvesEntry entry) async {
    try {
      final reply = await aiService.chat(
        '@nsfw',
        entryIds: [entry.id],
        entries: AiService.entriesPayload([entry]),
      );
      final error = reply.error;
      if (error != null && error.isNotEmpty) {
        return NsfwResult(available: false, score: null, labels: const [], error: error);
      }
      return _parse(reply.text);
    } catch (e, stack) {
      await reportService.recordError(e, stack);
      return NsfwResult(available: false, score: null, labels: const [], error: e.toString());
    }
  }

  NsfwResult _parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const NsfwResult.unknown();

    // Form 1: `nsfw:<score>[:<label>,<label>...]`
    if (text.startsWith('nsfw:')) {
      final parts = text.substring(5).split(':');
      final score = double.tryParse(parts[0].trim());
      if (score == null) return const NsfwResult.unknown();
      final labels = parts.length > 1 && parts[1].trim().isNotEmpty
          ? parts[1].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : const <String>[];
      return NsfwResult(available: true, score: score.clamp(0.0, 1.0), labels: labels);
    }

    // Form 2: plain number, e.g. `0.87`
    final asNumber = double.tryParse(text);
    if (asNumber != null) {
      return NsfwResult(available: true, score: asNumber.clamp(0.0, 1.0), labels: const []);
    }

    // Anything else: treat as unavailable
    return const NsfwResult.unknown();
  }
}

class NsfwResult {
  final bool available;
  final double? score;
  final List<String> labels;
  final String? error;

  const NsfwResult({
    required this.available,
    required this.score,
    this.labels = const [],
    this.error,
  });

  const NsfwResult.unknown() : available = false, score = null, labels = const [], error = null;

  String? tagFor({double threshold = 0.75}) {
    if (!available || score == null) return null;
    if (score! < threshold) return null;
    if (labels.isNotEmpty) return labels.first;
    return 'nsfw';
  }

  String get bucket {
    if (!available || score == null) return 'unknown';
    if (score! < 0.3) return 'safe';
    if (score! < 0.75) return 'uncertain';
    return 'nsfw';
  }
}

final nsfwService = NsfwService();
