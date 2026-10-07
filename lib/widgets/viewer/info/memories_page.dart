import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/favourites.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Google-Photos-style "Memories" — auto-curated collections generated
/// entirely from the local library (dates, resolution, favourites,
/// locations). No network, no ML.
class MemoriesPage extends StatelessWidget {
  static const routeName = '/viewer/info/memories';

  final CollectionLens? collection;
  final AvesEntry entry;

  const new({super.key, this.collection, required this.entry});

  @override
  Widget build(BuildContext context) {
    final entries = collection?.sortedEntries ?? [entry];
    final memories = _buildMemories(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: SafeArea(
        child: memories.isEmpty
            ? const _Empty()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: memories.length,
                itemBuilder: (context, i) => _MemoryCard(memory: memories[i]),
              ),
      ),
    );
  }

  List<_Memory> _buildMemories(List<AvesEntry> entries) {
    final now = DateTime.now();
    final result = <_Memory>[];

    List<AvesEntry> pick(bool Function(AvesEntry) test, {int max = 40}) {
      final list = entries.where(test).toList();
      if (list.length > max) list.sort((a, b) => (b.bestDate ?? DateTime(0)).compareTo(a.bestDate ?? DateTime(0)));
      return list.take(max).toList();
    }

    // On this day, N years ago
    for (var yearsAgo = 1; yearsAgo <= 5; yearsAgo++) {
      final target = DateTime(now.year - yearsAgo, now.month, now.day);
      final dayStart = DateTime(target.year, target.month, target.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final onDay = pick((e) {
        final d = e.bestDate;
        return d != null && !d.isBefore(dayStart) && d.isBefore(dayEnd);
      });
      if (onDay.isNotEmpty) {
        result.add(_Memory(
          title: yearsAgo == 1 ? 'A year ago today' : '$yearsAgo years ago today',
          subtitle: '${onDay.length} photos',
          entries: onDay,
        ));
      }
    }

    // Best of the current year — top resolution photos
    final thisYear = pick((e) {
      final d = e.bestDate;
      return d != null && d.year == now.year;
    }, max: 60);
    if (thisYear.length >= 5) {
      final best = [...thisYear]..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
      result.add(_Memory(
        title: 'Best of ${now.year}',
        subtitle: 'Highest resolution shots this year',
        entries: best.take(20).toList(),
      ));
    }

    // Favourites
    final favourites = pick((e) => e.isFavourite, max: 40);
    if (favourites.length >= 3) {
      result.add(_Memory(title: 'Favourites', subtitle: '${favourites.length} starred', entries: favourites));
    }

    // Recent (last 30 days)
    final cutoff = now.subtract(const Duration(days: 30));
    final recent = pick((e) {
      final d = e.bestDate;
      return d != null && d.isAfter(cutoff);
    }, max: 40);
    if (recent.length >= 5) {
      result.add(_Memory(title: 'Last 30 days', subtitle: '${recent.length} photos', entries: recent));
    }

    // Top rated
    final top = pick((e) => e.rating >= 4, max: 40);
    if (top.length >= 3) {
      result.add(_Memory(title: 'Top rated', subtitle: '${top.length} highly rated', entries: top));
    }

    return result;
  }
}

class _Memory {
  final String title;
  final String subtitle;
  final List<AvesEntry> entries;

  const _Memory({required this.title, required this.subtitle, required this.entries});
}

class _MemoryCard extends StatelessWidget {
  final _Memory memory;

  const _MemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cover = memory.entries.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PressableScale(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image(
                  image: cover.getThumbnail(extent: 512),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: colors.surfaceContainerHighest),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memory.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                    Text(memory.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.auto_awesome, size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 20),
          Text('No memories yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            'Memories are generated locally as you add photos — nothing leaves your device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Future<void> showMemoriesPage(BuildContext context, AvesEntry entry, {CollectionLens? collection}) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: MemoriesPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, __) => MemoriesPage(entry: entry, collection: collection),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
