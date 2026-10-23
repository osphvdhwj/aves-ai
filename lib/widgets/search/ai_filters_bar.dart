import 'package:aves/model/entry/entry.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
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

  const new({
    super.key,
    required this.entries,
    required this.selected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
          return PressableScale(
            enabled: enabled,
            onTap: enabled
                ? () {
                    final next = {...selected};
                    if (!next.remove(kind)) next.add(kind);
                    onSelectionChanged(next);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.secondaryContainer
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                border: isSelected
                    ? Border.all(color: colors.secondary, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    kind.icon,
                    size: 16,
                    color: enabled
                        ? (isSelected
                            ? colors.onSecondaryContainer
                            : colors.onSurfaceVariant)
                        : colors.onSurfaceVariant.withValues(alpha: .4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    kind.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? (isSelected
                              ? colors.onSecondaryContainer
                              : colors.onSurface)
                          : colors.onSurfaceVariant.withValues(alpha: .4),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
