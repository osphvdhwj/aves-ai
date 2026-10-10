import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Narrowing chip row shown above AI search results.
///
/// Categories map to companion-side filters once available. When a
/// category has no results the chip is disabled rather than hidden, so
/// the bar keeps a stable layout.
class AiFiltersBar extends StatefulWidget {
  final Map<AiFilterKind, int> counts;
  final ValueChanged<AiFilterKind>? onToggle;

  const new({super.key, this.counts = const {}, this.onToggle});

  @override
  State<AiFiltersBar> createState() => _AiFiltersBarState();
}

enum AiFilterKind {
  people('People', Symbols.people),
  objects('Objects', Symbols.category),
  places('Places', Symbols.place),
  dates('Dates', Symbols.schedule),
  documents('Documents', Symbols.description),
  screenshots('Screenshots', Symbols.screenshot_monitor);

  final String label;
  final IconData icon;
  const AiFilterKind(this.label, this.icon);
}

class _AiFiltersBarState extends State<AiFiltersBar> {
  final Set<AiFilterKind> _selected = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AiFilterKind.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kind = AiFilterKind.values[index];
          final count = widget.counts[kind] ?? 0;
          final selected = _selected.contains(kind);
          final enabled = count > 0;
          return PressableScale(
            enabled: enabled,
            onTap: enabled
                ? () {
                    setState(() {
                      if (!_selected.remove(kind)) _selected.add(kind);
                    });
                    widget.onToggle?.call(kind);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? colors.secondaryContainer : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                border: selected ? Border.all(color: colors.secondary, width: 1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    kind.icon,
                    size: 16,
                    color: enabled ? (selected ? colors.onSecondaryContainer : colors.onSurfaceVariant) : colors.onSurfaceVariant.withValues(alpha: .4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    kind.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled ? (selected ? colors.onSecondaryContainer : colors.onSurface) : colors.onSurfaceVariant.withValues(alpha: .4),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
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
