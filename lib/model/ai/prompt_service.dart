import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/favourites.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:collection/collection.dart';

/// Builds example prompts from the user's actual library.
/// Output is a list of strings that look natural as queries; ordering
/// puts the most "interesting" prompts first.
class AiPromptService {
  final CollectionSource source;

  AiPromptService(this.source);

  static const _minCountForDynamicPrompt = 3;

  List<String> buildDynamicPrompts({int max = 5}) {
    final entries = source.visibleEntries;
    if (entries.isEmpty) return const [];

    final prompts = <String>[];

    // Top album (by count)
    final albumCounts = <String, int>{};
    for (final e in entries) {
      final dir = e.directory;
      if (dir != null && dir.isNotEmpty) {
        albumCounts[dir] = (albumCounts[dir] ?? 0) + 1;
      }
    }
    final topAlbums = albumCounts.entries
        .where((e) => e.value >= _minCountForDynamicPrompt)
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(2)
        .toList();
    for (final a in topAlbums) {
      final name = _basename(a.key);
      if (name.isNotEmpty) prompts.add('Photos in $name');
    }

    // Top tag (by count)
    final tagCounts = <String, int>{};
    for (final e in entries) {
      for (final t in e.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries
        .where((e) => e.value >= _minCountForDynamicPrompt)
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(2)
        .toList();
    for (final t in topTags) {
      prompts.add('Photos tagged ${t.key}');
    }

    // Recent captures (last 30 days)
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final recentCount = entries.where((e) {
      final d = e.bestDate;
      return d != null && d.isAfter(cutoff);
    }).length;
    if (recentCount >= _minCountForDynamicPrompt) {
      prompts.add('Last 30 days');
    }

    // This year
    final yearStart = DateTime(now.year);
    final yearCount = entries.where((e) {
      final d = e.bestDate;
      return d != null && d.isAfter(yearStart);
    }).length;
    if (yearCount >= _minCountForDynamicPrompt) {
      prompts.add('Photos from this year');
    }

    // Favourites / high-rated
    final favCount = entries.where((e) => e.isFavourite || e.rating >= 4).length;
    if (favCount >= _minCountForDynamicPrompt) {
      prompts.add('Favourites and top rated');
    }

    return prompts.take(max).toList();
  }

  String _basename(String path) {
    final idx = path.lastIndexOf('/');
    return idx >= 0 ? path.substring(idx + 1) : path;
  }
}
