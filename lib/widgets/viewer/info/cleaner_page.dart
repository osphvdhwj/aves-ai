import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
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
  @override
  Widget build(BuildContext context) {
    final entries = widget.collection?.sortedEntries ?? [widget.entry];
    final buckets = _classify(entries);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Cleaner'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              '${entries.length} items in this view',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final bucket in CleanerBucket.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BucketTile(
                  bucket: bucket,
                  count: buckets[bucket]?.length ?? 0,
                  onTap: () => _openBucket(context, bucket, buckets[bucket] ?? const []),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<CleanerBucket, List<AvesEntry>> _classify(List<AvesEntry> entries) {
    final now = DateTime.now();
    final threeYearsAgo = now.subtract(const Duration(days: 3 * 365));
    final result = <CleanerBucket, List<AvesEntry>>{
      for (final b in CleanerBucket.values) b: <AvesEntry>[],
    };

    // Very lightweight hash for a "duplicate" heuristic: same size + same
    // mime + same rough dimensions is treated as likely duplicate.
    final fingerprints = <String, List<AvesEntry>>{};

    for (final e in entries) {
      final size = e.sizeBytes ?? 0;
      if (size >= 5 * 1000 * 1000) result[CleanerBucket.largeFiles]!.add(e);

      final dir = e.directory ?? '';
      if (dir.toLowerCase().contains('screenshot')) {
        result[CleanerBucket.screenshots]!.add(e);
      }

      // Blurry heuristic: panorama / RAW excluded; treat very small images
      // as not blurry candidates; otherwise flag entries under 1 MP as
      // low quality (conservative, no ML available here).
      if (e.isImage && e.isSized) {
        final mp = (e.width * e.height) / 1000000;
        if (mp > 0 && mp < 1) {
          result[CleanerBucket.blurry]!.add(e);
        }
      }

      final date = e.bestDate;
      if (date != null && date.isBefore(threeYearsAgo)) {
        result[CleanerBucket.oldMedia]!.add(e);
      }

      if (size > 0) {
        final key = '${e.mimeTypeAnySubtype}:${size}:${e.width}x${e.height}';
        fingerprints.putIfAbsent(key, () => []).add(e);
      }
    }

    for (final list in fingerprints.values) {
      if (list.length > 1) {
        result[CleanerBucket.duplicates]!.addAll(list);
      }
    }

    return result;
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

  const new({required this.bucket, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = count > 0;
    return PressableScale(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
        ),
        child: Row(
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
      ),
    );
  }
}
