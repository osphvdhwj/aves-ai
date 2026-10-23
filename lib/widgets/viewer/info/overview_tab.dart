import 'package:aves/model/entry/entry.dart';
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

  const new({
    super.key,
    required this.entry,
    required this.chipsSection,
    required this.locationSection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = settings.avesLocale;
    final use24hour = MediaQuery.alwaysUse24HourFormatOf(context);

    final title = entry.bestTitle ?? context.l10n.viewerInfoUnknown;
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
                // Title & Favorite
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mockup shows a Favorite pill/chip. We use a subtle container here.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.star, size: 16, color: colors.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            'Favorite',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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

                // People (Placeholder for Phase 3)
                Text(
                  'People',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Icon(Symbols.person, color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Text('1 photo (detected)', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      Icon(Symbols.chevron_right, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
