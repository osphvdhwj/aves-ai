import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/filters/covered/tag.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:flutter/widgets.dart';

/// Heuristic tag suggestions derived from the entry's album name and
/// existing metadata. Everything runs locally; nothing is inferred.
///
/// Examples:
///   album "Vacation 2023"    → "vacation", "2023"
///   album "Camera"           → (camera is filtered out as generic)
///   existing tag "beach"     → (kept, not repeated)
class TagSuggester {
  static const _generic = {
    'camera', 'dcim', 'download', 'downloads', 'pictures', 'photos',
    'images', 'screenshots', 'screenshot', 'movies', 'videos', 'video',
    'internal', 'storage', 'emulated', '0', 'sdcard', 'android',
    'whatsapp', 'telegram', 'signal', 'instagram', 'facebook',
  };

  static List<String> suggest(AvesEntry entry, {int max = 6}) {
    final existing = entry.tags.map((t) => t.toLowerCase()).toSet();
    final out = <String>[];

    void offer(String candidate) {
      final c = candidate.trim().toLowerCase();
      if (c.length < 3) return;
      if (c.length > 24) return;
      if (int.tryParse(c) != null) return;
      if (_generic.contains(c)) return;
      if (existing.contains(c)) return;
      if (out.contains(c)) return;
      out.add(c);
    }

    final dir = entry.directory ?? '';
    final segments = dir.split('/').where((s) => s.isNotEmpty).toList();
    // The album is the last non-generic segment.
    for (final seg in segments.reversed) {
      final cleaned = _cleanSegment(seg);
      if (cleaned == null) continue;
      for (final token in _tokenize(cleaned)) {
        offer(token);
      }
      if (out.isNotEmpty) break;
    }

    return out.take(max).toList();
  }

  static String? _cleanSegment(String seg) {
    if (seg.isEmpty) return null;
    final trimmed = seg.trim();
    if (trimmed.isEmpty) return null;
    if (_generic.contains(trimmed.toLowerCase())) return null;
    return trimmed;
  }

  static List<String> _tokenize(String s) {
    // split on non-letter/digit boundaries, plus camelCase transitions
    final spaced = s
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ');
    return spaced.split(' ').where((t) => t.isNotEmpty).toList();
  }
}

/// UI helper: applies one suggestion via the info action delegate.
Future<void> applySuggestedTag(
  BuildContext context, {
  required EntryInfoActionDelegate actionDelegate,
  required AvesEntry entry,
  required String tag,
}) async {
  await actionDelegate.quickTag(context, entry, TagFilter(tag));
}
