import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';

/// Google Photos-style top section for the info page.
///
/// Replaces the old bare rows at the top with:
///   - large date header
///   - editable caption line ("Add a caption" when empty)
///   - album row with a thumbnail preview
///   - People row (placeholder until face clustering ships)
class InfoHeaderSection extends StatelessWidget {
  final AvesEntry entry;
  final CollectionLens? collection;
  final EntryInfoActionDelegate actionDelegate;

  const new({
    super.key,
    required this.entry,
    this.collection,
    required this.actionDelegate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context, theme),
          const SizedBox(height: 12),
          _buildCaption(context, theme),
          const SizedBox(height: 20),
          _buildPeopleRow(context, theme, colors),
          const SizedBox(height: 20),
          _buildAlbumRow(context, theme, colors),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, ThemeData theme) {
    final date = entry.bestDate;
    final locale = settings.avesLocale;
    final use24hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final dateText = date != null ? formatDateTime(date, locale, use24hour) : '';

    return Text(
      dateText.isEmpty ? 'Undated' : dateText,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildCaption(BuildContext context, ThemeData theme) {
    final colors = theme.colorScheme;
    final caption = entry.catalogMetadata?.xmpTitle;
    final hasCaption = caption != null && caption.isNotEmpty;

    return PressableScale(
      onTap: () => actionDelegate.onActionSelected(context, entry, collection, EntryAction.editTitleDescription),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              hasCaption ? Icons.notes_outlined : Icons.add_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasCaption ? caption : 'Add a caption...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasCaption ? colors.onSurface : colors.onSurfaceVariant,
                  fontStyle: hasCaption ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleRow(BuildContext context, ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            PressableScale(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Face detection coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainerHighest,
                  border: Border.all(color: colors.outlineVariant, width: 1.5),
                ),
                child: Icon(Icons.person_add_alt_1_outlined, color: colors.onSurfaceVariant, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add someone',
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlbumRow(BuildContext context, ThemeData theme, ColorScheme colors) {
    final album = entry.directory;
    if (album == null) return const SizedBox.shrink();

    final albumName = collection?.source.getStoredAlbumDisplayName(context, album) ?? album.split('/').last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Albums',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        PressableScale(
          onTap: () {
            // future: jump to album's collection view
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image(
                    image: entry.getThumbnail(extent: 128),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: colors.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined, color: colors.onSurfaceVariant, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      albumName,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
