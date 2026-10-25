import 'package:aves/model/auto_tagger.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/nsfw_tags.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/nsfw_service.dart';

/// Batch auto-tagger: applies the rule-based [AutoTagger] proposals
/// across a whole collection without per-photo review, optionally adding
/// the companion's NSFW verdict per photo.
///
/// The engine is UI-agnostic: the caller supplies the tag-application
/// callback (normally the viewer's `quickTag` path, so metadata
/// persistence and notifier fan-out behave exactly like the tag editor)
/// plus progress/cancel hooks.
class AutoTagEngine {
  /// Proposals below this confidence are skipped in batch mode.
  final double minConfidence;

  /// Whether to consult the companion's NSFW classifier per photo.
  final bool nsfw;

  /// NSFW score at or above which the corresponding tag is applied.
  final double nsfwThreshold;

  const AutoTagEngine({
    this.minConfidence = 0.75,
    this.nsfw = true,
    this.nsfwThreshold = 0.75,
  });

  Future<AutoTagRunReport> run({
    required List<AvesEntry> entries,
    required Future<void> Function(AvesEntry entry, String tag) applyTag,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    await NsfwTags.load();
    final tagger = AutoTagger();
    final useNsfw = nsfw && await aiService.hasCapability('nsfw');

    var applied = 0;
    var skipped = 0;
    var scanned = 0;
    var cancelled = false;

    for (final entry in entries) {
      if (isCancelled?.call() ?? false) {
        cancelled = true;
        break;
      }
      try {
        final proposals = tagger
            .proposeNew(entry)
            .where((p) => p.confidence >= minConfidence);
        for (final p in proposals) {
          await applyTag(entry, p.tag);
          applied++;
        }
        if (useNsfw) {
          try {
            final verdict = await nsfwService.classify(entry);
            final tag = verdict.tagFor(threshold: nsfwThreshold);
            if (tag != null) {
              await applyTag(entry, tag);
              applied++;
            }
          } catch (_) {
            // per-photo NSFW failures must not abort the batch
          }
        }
      } catch (_) {
        skipped++;
      }
      scanned++;
      onProgress?.call(scanned, entries.length);
    }

    return AutoTagRunReport(
      scanned: scanned,
      applied: applied,
      skipped: skipped,
      cancelled: cancelled,
      total: entries.length,
    );
  }
}

class AutoTagRunReport {
  final int scanned;
  final int applied;
  final int skipped;
  final bool cancelled;
  final int total;

  const AutoTagRunReport({
    required this.scanned,
    required this.applied,
    required this.skipped,
    required this.cancelled,
    required this.total,
  });
}
