import 'dart:io';
import 'dart:typed_data';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Duplicate finder UI.
///
/// Groups entries by a stable fingerprint (size + mime + dimensions).
/// Real-world duplicate detection typically needs perceptual hashing,
/// which the AI companion can provide; the fingerprint below is a
/// conservative approximation that flags only likely-exact copies.
class DuplicatesPage extends StatelessWidget {
  static const routeName = '/viewer/info/duplicates';

  final CollectionLens? collection;
  final AvesEntry entry;

  const new({super.key, this.collection, required this.entry});

  @override
  Widget build(BuildContext context) {
    final entries = collection?.sortedEntries ?? [entry];
    final groups = _groupDuplicates(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicates')),
      body: SafeArea(
        child: groups.isEmpty
            ? _EmptyState(entryCount: entries.length)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: groups.length,
                itemBuilder: (context, index) => _GroupCard(group: groups[index], index: index),
              ),
      ),
    );
  }

  List<_DuplicateGroup> _groupDuplicates(List<AvesEntry> entries) {
    // stage 1: cheap fingerprint (size + mime)
    final byFingerprint = <String, List<AvesEntry>>{};
    for (final e in entries) {
      final size = e.sizeBytes ?? 0;
      if (size <= 0) continue;
      final key = '${e.mimeTypeAnySubtype}:$size';
      byFingerprint.putIfAbsent(key, () => []).add(e);
    }

    // stage 2: content hash for same-fingerprint entries with accessible paths
    final groups = <_DuplicateGroup>[];
    for (final candidates in byFingerprint.values) {
      if (candidates.length < 2) continue;
      final byHash = <String, List<AvesEntry>>{};
      for (final e in candidates) {
        final hash = _contentHash(e);
        byHash.putIfAbsent(hash, () => []).add(e);
      }
      for (final g in byHash.values) {
        if (g.length > 1) groups.add(_DuplicateGroup(entries: g));
      }
    }
    return groups;
  }

  /// BLAKE-ish rolling hash over the first and last 64 KB of the file.
  /// Full-file hashing is expensive; head+tail is enough to distinguish
  /// real duplicates from size collisions while staying fast.
  String _contentHash(AvesEntry e) {
    final path = e.path;
    if (path == null || path.isEmpty) {
      // fall back to the cheap fingerprint for entries without a path
      return 'nopath:${e.mimeTypeAnySubtype}:${e.sizeBytes}:${e.width}x${e.height}';
    }
    try {
      final file = File(path);
      if (!file.existsSync()) return 'missing:$path';
      final raf = file.openSync();
      try {
        const window = 64 * 1024;
        final size = raf.lengthSync();
        final head = Uint8List.fromList(raf.readSync(window));
        Uint8List tail = Uint8List(0);
        if (size > window) {
          raf.setPositionSync(size - window);
          tail = Uint8List.fromList(raf.readSync(window));
        }
        // FNV-1a over head+tail — cheap, adequate for equality checks
        var h = 0xcbf29ce484222325;
        for (final b in head) {
          h ^= b;
          h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
        }
        for (final b in tail) {
          h ^= b;
          h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
        }
        return h.toRadixString(16).padLeft(16, '0');
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return 'err:$path';
    }
  }
}

/// Keeps the "best" entry and marks the rest for deletion suggestion.
/// Preference order:
///   1. higher resolution
///   2. earlier EXIF capture date (original, not re-encoded)
///   3. shorter path (heuristic for canonical location)
AvesEntry bestOf(List<AvesEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final pa = (a.width * a.height);
    final pb = (b.width * b.height);
    if (pa != pb) return pb.compareTo(pa);
    final da = a.bestDate;
    final db = b.bestDate;
    if (da != null && db != null && da != db) return da.compareTo(db);
    return (a.path ?? '').length.compareTo((b.path ?? '').length);
  });
  return sorted.first;
}

class _DuplicateGroup {
  final List<AvesEntry> entries;

  const _DuplicateGroup({required this.entries});
}

class _GroupCard extends StatelessWidget {
  final _DuplicateGroup group;
  final int index;

  const _GroupCard({required this.group, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = group.entries;
    final totalBytes = entries.map((e) => e.sizeBytes ?? 0).fold<int>(0, (a, b) => a + b);
    final keep = bestOf(entries);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.content_copy, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Group ${index + 1} · ${entries.length} items',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  _formatBytes(totalBytes),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (context, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final isKeep = identical(e, keep);
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image(
                            image: e.getThumbnail(extent: 160),
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, _) => ColoredBox(color: colors.surfaceContainerHighest),
                          ),
                        ),
                      ),
                      if (isKeep)
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Keep',
                              style: theme.textTheme.labelSmall?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Auto-resolve needs the AI companion.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Auto-resolve'),
                ),
                const SizedBox(width: 4),
                FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select and delete is not yet wired.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1 << 30) return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
    if (bytes >= 1 << 20) return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

class _EmptyState extends StatelessWidget {
  final int entryCount;

  const _EmptyState({required this.entryCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.content_copy, size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 20),
          Text('No duplicates found', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            'Scanned $entryCount items using size and dimensions. '
            'Perceptual duplicate detection lands when the AI companion ships.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Future<void> showDuplicatesPage(BuildContext context, AvesEntry entry, {CollectionLens? collection}) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: DuplicatesPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, _) => DuplicatesPage(entry: entry, collection: collection),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
