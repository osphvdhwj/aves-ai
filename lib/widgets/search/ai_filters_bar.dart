import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Filter bar shown above AI search results.
///
/// Filters happen **locally on the returned entries**, not on the
/// companion. That keeps the companion contract simple (still returns
/// entryIds) while giving the user a way to narrow down.
///
/// This is a controlled widget: the parent owns [selected] and reacts
/// to [onSelectionChanged]. That lets the parent preset chips based on
/// the query (e.g. "videos" auto-selects Videos).
class AiFiltersBar extends StatelessWidget {
  final List<AvesEntry> entries;
  final Set<AiFilterKind> selected;
  final ValueChanged<Set<AiFilterKind>> onSelectionChanged;

  const AiFiltersBar({
    super.key,
    required this.entries,
    required this.selected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    int countOf(AiFilterKind k) => entries.where(k.test).length;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: AiFilterKind.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kind = AiFilterKind.values[index];
          final count = countOf(kind);
          final isSelected = selected.contains(kind);
          final enabled = count > 0;
          return FilterChip(
            selected: isSelected,
            avatar: Icon(
              kind.icon,
              size: 16,
              color: enabled ? colors.onSurfaceVariant : colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            label: Text(count > 0 ? '${kind.label} $count' : kind.label),
            onSelected: enabled
                ? (_) {
                    final next = {...selected};
                    if (!next.remove(kind)) next.add(kind);
                    onSelectionChanged(next);
                  }
                : null,
          );
        },
      ),
    );
  }
}

enum AiFilterKind {
  images('Images', Symbols.image),
  videos('Videos', Symbols.movie),
  animated('Animated', Symbols.animated_images);

  final String label;
  final IconData icon;
  const AiFilterKind(this.label, this.icon);

  bool test(AvesEntry e) {
    switch (this) {
      case images:
        return e.isImage && !e.isAnimated;
      case videos:
        return e.isVideo && !e.isAnimated;
      case animated:
        return e.isAnimated;
    }
  }
}
