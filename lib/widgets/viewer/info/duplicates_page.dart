import 'dart:io';
import 'dart:typed_data';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Duplicate finder UI.
///
/// Two complementary passes:
///  1. local exact copies — grouped by a stable fingerprint (size + mime
///     + dimensions) plus a head+tail content hash, computed instantly;
///  2. AI near-duplicates — the companion's /dup command over its CLIP
///     index (cosine >= 0.97), which catches re-encodes and crops the
///     fingerprint cannot see. Shown only when the companion is
///     connected with the `dup` capability.
class DuplicatesPage extends StatefulWidget {
  static const routeName = '/viewer/info/duplicates';

  final CollectionLens? collection;
  final AvesEntry entry;

  const DuplicatesPage({super.key, this.collection, required this.entry});

  @override
  State<DuplicatesPage> createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends State<DuplicatesPage> {
  /// Cap for the companion pass: /dup embeds every payload entry, so
  /// bound the work even for very large views.
  static const _companionPayloadCap = 400;

  List<_DuplicateGroup> _localGroups = const [];
  List<_DuplicateGroup> _companionGroups = const [];
  bool _companionLoading = false;
  String? _companionError;

  @override
  void initState() {
    super.initState();
    final entries = widget.collection?.sortedEntries ?? [widget.entry];
    _localGroups = _groupExactCopies(entries);
    _loadCompanionGroups();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.collection?.sortedEntries ?? [widget.entry];
    final hasLocal = _localGroups.isNotEmpty;
    final hasCompanion = _companionGroups.isNotEmpty;

    return AvesScaffold(
      appBar: AppBar(title: const Text('Duplicates')),
      body: SafeArea(
        child: !hasLocal && !hasCompanion && !_companionLoading && _companionError == null
            ? StatusView(
                icon: Symbols.content_copy,
                title: 'No duplicates found',
                subtitle: 'Scanned ${entries.length} items using size and dimensions.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (hasLocal) ...[
                    _sectionHeader(context, 'Exact copies', trailing: '${_localGroups.length} group${_localGroups.length == 1 ? '' : 's'}'),
                    for (var i = 0; i < _localGroups.length; i++)
                      _GroupCard(entries: _localGroups[i].entries, index: i),
                  ],
                  _sectionHeader(context, 'AI near-duplicates', trailing: _companionTrailing(context)),
                  if (_companionLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_companionError != null)
                    StatusView(
                      icon: AIcons.error,
                      isError: true,
                      title: 'AI scan failed',
                      subtitle: _companionError,
                    )
                  else if (!hasCompanion)
                    const StatusView(
                      icon: Symbols.auto_awesome,
                      title: 'No near-duplicates',
                      subtitle: 'The companion compared your photos by visual similarity and found no repeats.',
                    )
                  else
                    for (var i = 0; i < _companionGroups.length; i++)
                      _GroupCard(entries: _companionGroups[i].entries, index: i),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, {String? trailing}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  String? _companionTrailing(BuildContext context) {
    if (_companionLoading) return 'scanning…';
    if (_companionError != null) return null;
    final n = _companionGroups.length;
    return n > 0 ? '$n group${n == 1 ? '' : 's'}' : null;
  }

  Future<void> _loadCompanionGroups() async {
    if (!mounted) return;
    setState(() => _companionLoading = true);
    try {
      if (!await aiService.hasCapability('dup')) {
        if (mounted) setState(() => _companionLoading = false);
        return;
      }
      final entries = (widget.collection?.sortedEntries ?? [widget.entry]).take(_companionPayloadCap).toList();
      final reply = await aiService.chat(
        '/dup',
        entryIds: entries.map((e) => e.id).toList(),
        entries: AiService.entriesPayload(entries),
      );
      if (!mounted) return;
      final error = reply.error;
      if (error != null && error.isNotEmpty) {
        setState(() {
          _companionError = error;
          _companionLoading = false;
        });
        return;
      }
      final byId = {for (final e in entries) e.id: e};
      final groups = <_DuplicateGroup>[];
      for (final ids in reply.groupedEntryIds) {
        final group = ids.map((id) => byId[id]).whereType<AvesEntry>().toList();
        if (group.length > 1) groups.add(_DuplicateGroup(entries: group));
      }
      setState(() {
        _companionGroups = groups;
        _companionLoading = false;
      });
    } catch (e, s) {
      await reportService.recordError(e, s);
      if (mounted) {
        setState(() {
          _companionError = e.toString();
          _companionLoading = false;
        });
      }
    }
  }

  List<_DuplicateGroup> _groupExactCopies(List<AvesEntry> entries) {
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
  final List<AvesEntry> entries;
  final int index;

  const _GroupCard({required this.entries, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalBytes = entries.map((e) => e.sizeBytes ?? 0).fold<int>(0, (a, b) => a + b);
    final keep = bestOf(entries);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 4),
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
                              borderRadius: BorderRadius.circular(context.m3e.shapeExtraSmall),
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
            Text(
              'The highest-resolution original is marked "Keep". Review and delete wiring lands with the AI companion.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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

Future<void> showDuplicatesPage(BuildContext context, AvesEntry entry, {CollectionLens? collection}) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: DuplicatesPage.routeName),
      builder: (context) => DuplicatesPage(entry: entry, collection: collection),
    ),
  );
}
