import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

class InfoDateHeader extends StatelessWidget {
  final AvesEntry entry;

  const InfoDateHeader({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = entry.bestDate;
    if (date == null) return const SizedBox();

    // Use Aves' calendar-aware formatters, not raw intl. The custom
    // AvesLocale understands Hijri, Persian, and locale-specific
    // orderings; Localizations.localeOf would fall back to Gregorian.
    final locale = settings.avesLocale;
    final use24hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.m3e;

    // Compose 'Fri, Jan 10, 2025' from MMMEd + y. AvesLocale has no
    // standalone EEEE getter, and yMMMMd drops the weekday entirely.
    final datePart = '${locale.MMMEd(date)}, ${locale.y(date)}';
    final timePart = formatTime(date, locale, use24hour);

    final baseStyle = theme.textTheme.headlineSmall;
    final baseWeight = baseStyle?.fontWeight ?? FontWeight.w400;
    final steps = (tokens.emphasizedWeightDelta / 100).round();
    final emphasizedIndex = (baseWeight.index + steps).clamp(0, FontWeight.values.length - 1);
    final emphasizedWeight = FontWeight.values[emphasizedIndex];

    // No outer Padding: the parent InfoHeaderSection already wraps this
    // widget in fromLTRB(16, 8, 16, 16). Adding our own would double-up
    // to 36px horizontal.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          datePart,
          style: baseStyle?.copyWith(
            fontWeight: emphasizedWeight,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          timePart,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
