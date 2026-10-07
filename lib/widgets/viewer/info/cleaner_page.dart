import 'dart:async';
import 'dart:ui' as ui;

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/viewer/info/image_quality.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Local cleaner buckets. Each bucket is computed from the entries the
/// caller supplies — no native model needed for the classification; it is
/// all pure Dart over the collection.
enum CleanerBucket {
  largeFiles('Large files', 'Over 5 MB', Symbols.storage),
  screenshots('Screenshots', 'Likely screenshots to clear', Symbols.screenshot_monitor),
  blurry('Blurry', 'Low clarity shots (heuristic)', Symbols.blur_on),
  dark('Dark', 'Underexposed or near-black frames', Symbols.brightness_low),
  duplicates('Duplicates', 'Same content, different files', Symbols.content_copy),
  oldMedia('Very old', 'Older than 3 years', Symbols.history);

  final String title;
  final String subtitle;
  final IconData icon;

  const CleanerBucket(this.title, this.subtitle, this.icon);
}

class CleanerPage extends StatefulWidget {
  static const routeName = '/viewer/info/cleaner';

  final CollectionLens? collection;
  final AvesEntry entry;

  const new({super.key, this.collection, required this.entry});

  @override
  State<CleanerPage> createState() => _CleanerPageState();
}

class _CleanerPageState extends State<CleanerPage> {
  Future<Map<CleanerBucket, List<AvesEntry>>>? _classificationFuture;
  List<AvesEntry> _cachedEntries = const [];

  @override
  void initState() {
    super.initState();
    _scheduleClassification();
  }

  @override
  void didUpdateWidget(covariant CleanerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection != widget.collection || oldWidget.entry != widget.entry) {
      _scheduleClassification();
    }
  }

  void _scheduleClassification() {
    _cachedEntries = widget.collection?.sortedEntries ?? [widget.entry];
    _classificationFuture = _classify(_cachedEntries);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _cachedEntries;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Cleaner'),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<CleanerBucket, List<AvesEntry>>>(
          future: _classificationFuture,
          builder: (context, snapshot) {
            final buckets = snapshot.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  '${entries.length} items in this view',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (buckets == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (final bucket in CleanerBucket.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BucketTile(
                        bucket: bucket,
                        count: buckets[bucket]?.length ?? 0,
                        preview: buckets[bucket] ?? const [],
                        onTap: () => _openBucket(context, bucket, buckets[bucket] ?? const []),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<CleanerBucket, List<AvesEntry>>> _classify(List<AvesEntry> entries) async {
    final now = DateTime.now();
    final threeYearsAgo = now.subtract(const Duration(days: 3 * 365));
    final result = <CleanerBucket, List<AvesEntry>>{
      for (final b in CleanerBucket.values) b: <AvesEntry>[],
    };

    final fingerprints = <String, List<AvesEntry>>{};
    // image-analysis candidates (bounded count to avoid long scans)
    final analysisCandidates = <AvesEntry>[];
    const maxAnalyze = 120;

    for (final e in entries) {
      final size = e.sizeBytes ?? 0;
      if (size >= 5 * 1000 * 1000) result[CleanerBucket.largeFiles]!.add(e);

      final dir = e.directory ?? '';
      if (dir.toLowerCase().contains('screenshot')) {
        result[CleanerBucket.screenshots]!.add(e);
      }

      final date = e.bestDate;
      if (date != null && date.isBefore(threeYearsAgo)) {
        result[CleanerBucket.oldMedia]!.add(e);
      }

      if (size > 0) {
        final key = '${e.mimeTypeAnySubtype}:${size}:${e.width}x${e.height}';
        fingerprints.putIfAbsent(key, () => []).add(e);
      }

      if (e.isImage && e.isSized && analysisCandidates.length < maxAnalyze) {
        analysisCandidates.add(e);
      }
    }

    // Real image analysis: Laplacian variance + mean luma on downsampled RGBA.
    for (final e in analysisCandidates) {
      final stats = await _analyze(e);
      if (stats == null) continue;
      if (stats.blurry) result[CleanerBucket.blurry]!.add(e);
      if (stats.dark) result[CleanerBucket.dark]!.add(e);
    }

    for (final list in fingerprints.values) {
      if (list.length > 1) {
        result[CleanerBucket.duplicates]!.addAll(list);
      }
    }

    return result;
  }

  Future<_QualityStats?> _analyze(AvesEntry e) async {
    try {
      final provider = e.getThumbnail(extent: 256);
      final image = await _decode(provider);
      if (image == null) return null;
      final w = image.width;
      final h = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null) return null;
      final bytes = data.buffer.asUint8List();
      final variance = ImageQuality.laplacianVariance(bytes, w, h);
      final mean = ImageQuality.meanLuma(bytes, w, h);
      // thresholds tuned conservatively; expect companion to refine later
      return _QualityStats(
        blurry: variance > 0 && variance < 60,
        dark: mean < 30,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _decode(ImageProvider provider) async {
    final stream = provider.resolve(ImageConfiguration.empty);
    final completer = Completer<ui.Image?>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info.image);
      },
      onError: (e, s) {
        stream.removeListener(listener);
        completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void _openBucket(BuildContext context, CleanerBucket bucket, List<AvesEntry> entries) {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nothing in "${bucket.title}"'), duration: const Duration(seconds: 1)),
      );
      return;
    }
    Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: CleanerBucketPage.routeName),
        builder: (context) => CleanerBucketPage(bucket: bucket, entries: entries),
      ),
    );
  }
}

class _QualityStats {
  final bool blurry;
  final bool dark;

  const _QualityStats({required this.blurry, required this.dark});
}

class CleanerBucketPage extends StatelessWidget {
  static const routeName = '/viewer/info/cleaner/bucket';

  final CleanerBucket bucket;
  final List<AvesEntry> entries;

  const new({super.key, required this.bucket, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bucket.title),
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final e = entries[index];
            return PressableScale(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                child: Image(
                  image: e.getThumbnail(extent: 256),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BucketTile extends StatelessWidget {
  final CleanerBucket bucket;
  final int count;
  final VoidCallback onTap;
  final List<AvesEntry> preview;

  const new({required this.bucket, required this.count, required this.onTap, this.preview = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = count > 0;
    final previews = preview.take(6).toList();
    return PressableScale(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(bucket.icon, size: 22, color: enabled ? colors.primary : colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bucket.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        bucket.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (previews.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: previews.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final e = previews[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(context.m3e.shapeExtraSmall),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image(
                          image: e.getThumbnail(extent: 80),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(color: colors.surfaceContainerHighest),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
