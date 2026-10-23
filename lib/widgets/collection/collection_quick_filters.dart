import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class CollectionQuickFilters extends StatelessWidget {
  final CollectionLens collection;

  const new({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: collection.filterChangeNotifier,
      builder: (context, _) {
        final active = collection.visibleFilters;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildChip(
                context,
                label: context.l10n.removeEntryMetadataDialogAll,
                icon: Symbols.grid_view,
                selected: active.isEmpty,
                onTap: () {
                  final current = active.toList();
                  for (final f in current) {
                    collection.removeFilter(f);
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildChip(
                context,
                label: MimeFilter.image.getLabel(context),
                icon: Symbols.image,
                selected: active.contains(MimeFilter.image),
                onTap: () => collection.addFilters({MimeFilter.image}),
              ),
              const SizedBox(width: 8),
              _buildChip(
                context,
                label: MimeFilter.video.getLabel(context),
                icon: Symbols.play_circle,
                selected: active.contains(MimeFilter.video),
                onTap: () => collection.addFilters({MimeFilter.video}),
              ),
              const SizedBox(width: 8),
              _buildChip(
                context,
                label: FavouriteFilter.instance.getLabel(context),
                icon: Symbols.favorite,
                selected: active.contains(FavouriteFilter.instance),
                onTap: () => collection.addFilters({FavouriteFilter.instance}),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.m3e;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(tokens.shapeExtraLarge * 2),
          border: Border.all(
            color: selected ? Colors.transparent : colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimaryContainer : colors.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
