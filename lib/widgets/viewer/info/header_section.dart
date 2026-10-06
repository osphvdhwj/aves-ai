import 'dart:async';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/filters/covered/stored_album.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/theme/text.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/viewer/controls/notifications.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Google Photos-style top section for the info page.
///
/// M3E-styled header:
///   - large emphasized date header
///   - editable caption line ("Add a caption" when empty)
///   - People row (placeholder until face clustering ships)
///   - Album row with thumbnail, name, and item count
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
    final tokens = context.m3e;
    final date = entry.bestDate;
    final locale = settings.avesLocale;
    final use24hour = MediaQuery.alwaysUse24HourFormatOf(context);
    // Google Photos style: "Fri, Jan 10, 2025 · 9:36 AM"
    final dateText = date != null ? '${locale.MMMEd(date)}, ${locale.y(date)}${AText.separator}${formatTime(date, locale, use24hour)}' : '';

    final baseStyle = theme.textTheme.headlineMedium ?? theme.textTheme.headlineSmall;
    final baseWeight = baseStyle?.fontWeight ?? FontWeight.w400;
    final steps = (tokens.emphasizedWeightDelta / 100).round();
    final emphasizedIndex = (baseWeight.index + steps).clamp(0, FontWeight.values.length - 1);
    final emphasizedWeight = FontWeight.values[emphasizedIndex];

    return Text(
      dateText.isEmpty ? 'Undated' : dateText,
      style: baseStyle?.copyWith(
        fontWeight: emphasizedWeight,
        letterSpacing: -0.5,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCaption(BuildContext context, ThemeData theme) {
    return _CaptionRow(
      entry: entry,
      collection: collection,
      actionDelegate: actionDelegate,
    );
  }

  Widget _buildPeopleRow(BuildContext context, ThemeData theme, ColorScheme colors) {
    void onTap() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face detection coming soon'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    Widget circle() => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant, width: 1.5),
      ),
    );

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
        PressableScale(
          onTap: onTap,
          child: Row(
            children: [
              circle(),
              const SizedBox(width: 8),
              circle(),
              const SizedBox(width: 8),
              circle(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Add someone',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumRow(BuildContext context, ThemeData theme, ColorScheme colors) {
    final album = entry.directory;
    if (album == null) return const SizedBox.shrink();

    final tokens = context.m3e;
    final source = collection?.source;
    final albumName = source?.getStoredAlbumDisplayName(context, album) ?? album.split('/').last;
    final itemCount = source?.albumEntryCount(StoredAlbumFilter(album, null));
    final subtitle = itemCount != null
        ? (itemCount == 1 ? '1 item' : '$itemCount items')
        : album;

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
            final displayName = source?.getStoredAlbumDisplayName(context, album) ?? album;
            SelectFilterNotification(StoredAlbumFilter(album, displayName)).dispatch(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(tokens.shapeMedium),
            ),
            child: Row(
              children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.shapeSmall),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image(
                    image: entry.getThumbnail(extent: 128),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: colors.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Symbols.image, color: colors.onSurfaceVariant, size: 20),
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
                        subtitle,
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
        ),
      ],
    );
  }
}

/// Caption surface: reads the XMP title from catalog metadata (sync) and the
/// description via overlay metadata (async, live from the file). Reloads when
/// the entry's metadata change notifier fires or when the entry changes.
class _CaptionRow extends StatefulWidget {
  final AvesEntry entry;
  final CollectionLens? collection;
  final EntryInfoActionDelegate actionDelegate;

  const new({
    required this.entry,
    this.collection,
    required this.actionDelegate,
  });

  @override
  State<_CaptionRow> createState() => _CaptionRowState();
}

class _CaptionRowState extends State<_CaptionRow> {
  String? _description;

  AvesEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    entry.metadataChangeNotifier.addListener(_onMetadataChanged);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _CaptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      oldWidget.entry.metadataChangeNotifier.removeListener(_onMetadataChanged);
      entry.metadataChangeNotifier.addListener(_onMetadataChanged);
      _description = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    entry.metadataChangeNotifier.removeListener(_onMetadataChanged);
    super.dispose();
  }

  void _onMetadataChanged() {
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final fields = await metadataFetchService.getOverlayMetadata(entry, {MetadataSyntheticField.description});
      if (!mounted) return;
      setState(() => _description = fields.description);
    } catch (_) {
      if (!mounted) return;
      setState(() => _description = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.m3e;
    final colors = theme.colorScheme;
    final title = (entry.catalogMetadata?.xmpTitle ?? '').trim();
    final description = (_description ?? '').trim();
    final hasCaption = title.isNotEmpty || description.isNotEmpty;

    return PressableScale(
      onTap: () => widget.actionDelegate.onActionSelected(context, entry, widget.collection, EntryAction.editTitleDescription),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(tokens.shapeMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                hasCaption ? Symbols.notes : Symbols.add,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasCaption
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (title.isNotEmpty && description.isNotEmpty) const SizedBox(height: 2),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Text(
                      'Add a caption...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
