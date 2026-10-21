import 'package:aves/model/entry/entry.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class InfoDateHeader extends StatelessWidget {
  final AvesEntry entry;

  const InfoDateHeader({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = entry.bestDate;
    if (date == null) return const SizedBox();

    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMMd(locale).format(date),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat.EEEE(locale).format(date)} · ${DateFormat.jm(locale).format(date)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
