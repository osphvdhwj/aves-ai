import 'package:flutter/services.dart';

/// Bundled vocabulary of NSFW tags (`assets/nsfw_tags.txt`, one per line).
///
/// Loaded once and cached. Used by the tag suggester so album-name
/// derived suggestions stick to tags the user has already classified as
/// NSFW, and as an input for future content-warning / filter features.
class NsfwTags {
  static const assetPath = 'assets/nsfw_tags.txt';

  static List<String>? _cache;
  static Set<String>? _lowerCache;

  /// Loads the vocabulary, sorted and de-duplicated. Idempotent.
  static Future<List<String>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    final seen = <String>{};
    final list = <String>[];
    for (var line in raw.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;
      if (!seen.add(line.toLowerCase())) continue;
      list.add(line);
    }
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _cache = list;
    _lowerCache = seen;
    return list;
  }

  /// Synchronous view — callers must have awaited [load] first.
  static List<String>? get cached => _cache;

  /// `true` if the vocabulary contains [tag] (case-insensitive).
  static bool contains(String tag) => _lowerCache?.contains(tag.toLowerCase()) ?? false;

  /// Case-insensitive prefix search, capped at [limit] results.
  static Future<List<String>> prefix(String query, {int limit = 10}) async {
    final vocab = await load();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return vocab.take(limit).toList();
    final hits = <String>[];
    for (final t in vocab) {
      if (t.toLowerCase().startsWith(q)) {
        hits.add(t);
        if (hits.length >= limit) break;
      }
    }
    return hits;
  }

  /// Fuzzy contains-anywhere search, capped at [limit].
  static Future<List<String>> search(String query, {int limit = 20}) async {
    final vocab = await load();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return vocab.take(limit).toList();
    final hits = <String>[];
    for (final t in vocab) {
      if (t.toLowerCase().contains(q)) {
        hits.add(t);
        if (hits.length >= limit) break;
      }
    }
    return hits;
  }
}
