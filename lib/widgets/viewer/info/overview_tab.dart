import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/filters/covered/stored_album.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/viewer/controls/notifications.dart';
import 'package:aves/widgets/viewer/info/people_page.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class OverviewTab extends StatelessWidget {
  final AvesEntry entry;
  final Widget chipsSection;
  final Widget locationSection;

  final CollectionLens? collection;

  const new({
    super.key,
    required this.entry,
    this.collection,
    required this.chipsSection,
    required this.locationSection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = settings.avesLocale;
    final use24hour = MediaQuery.alwaysUse24HourFormatOf(context);

    final date = entry.bestDate;
    final dateText = date != null ? formatDateTime(date, locale, use24hour) : context.l10n.viewerInfoUnknown;
    final sizeText = entry.sizeBytes != null ? formatFileSize(locale, entry.sizeBytes!) : context.l10n.viewerInfoUnknown;
    final formatText = entry.mimeType.split('/').last.toUpperCase();
    final resolutionText = '${entry.width} x ${entry.height}';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Date & Location
                Row(
                  children: [
                    Icon(Symbols.calendar_today, size: 16, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(dateText, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Icon(Symbols.location_on, size: 16, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entry.hasGps ? 'Location available' : 'No location',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tags
                chipsSection,
                const SizedBox(height: 24),

                // Quick Info Grid
                Text(
                  'Quick Info',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _InfoCard(icon: Symbols.photo_size_select_large, title: 'Resolution', value: resolutionText)),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoCard(icon: Symbols.data_usage, title: 'Size', value: sizeText)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _InfoCard(icon: Symbols.insert_drive_file, title: 'Format', value: formatText)),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoCard(icon: Symbols.stars, title: 'Quality', value: '100%')),
                  ],
                ),
                const SizedBox(height: 24),

                // Location Section
                if (entry.hasGps) ...[
                  locationSection,
                  const SizedBox(height: 24),
                ],

                _buildPeopleRow(context),
                const SizedBox(height: 24),
                _buildAlbumRow(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPeopleRow(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FutureBuilder<AiHealth>(
      future: aiService.health(),
      builder: (context, snap) {
        final supported = snap.data?.connected == true && snap.data!.has('person');
        void onTap() {
          if (!supported) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Face recognition needs the AVES+ Tools companion.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          showPeoplePage(context);
        }

        final dim = colors.onSurfaceVariant.withValues(alpha: .4);
        Widget circle() => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: supported ? colors.surfaceContainerHighest : colors.surfaceContainerLowest,
            border: Border.all(
              color: supported ? colors.outlineVariant : colors.outlineVariant.withValues(alpha: .4),
              width: 1.5,
            ),
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
                      style: theme.textTheme.bodyMedium?.copyWith(color: dim),
                    ),
                  ),
                  Icon(Symbols.chevron_right, size: 18, color: dim),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumRow(BuildContext context) {
    final album = entry.directory;
    if (album == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
                const SizedBox(width: 8),
                Icon(Symbols.chevron_right, size: 20, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const new({super.key, required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(title, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
