import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Object category browser.
///
/// UI shell. Categories are populated by the AI companion once object
/// recognition lands. Until then the page renders the fixed category
/// catalogue so the layout is final and reviewable.
class ObjectsPage extends StatelessWidget {
  static const routeName = '/viewer/info/objects';

  /// Optional counts from the companion, keyed by category id.
  final Map<String, int> counts;

  const new({super.key, this.counts = const {}});

  static const _categories = <(String, String, IconData)>[
    ('food', 'Food & drink', Symbols.restaurant),
    ('nature', 'Nature', Symbols.eco),
    ('animals', 'Animals', Symbols.pets),
    ('vehicles', 'Vehicles', Symbols.directions_car),
    ('buildings', 'Buildings', Symbols.apartment),
    ('people', 'People', Symbols.people),
    ('documents', 'Documents', Symbols.description),
    ('art', 'Art', Symbols.palette),
    ('sports', 'Sports', Symbols.sports_basketball),
    ('electronics', 'Electronics', Symbols.devices),
    ('fashion', 'Fashion', Symbols.checkroom),
    ('screenshots', 'Screenshots', Symbols.screenshot_monitor),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objects')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final (id, label, icon) = _categories[index];
            final count = counts[id];
            return _CategoryCard(id: id, label: label, icon: icon, count: count);
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final int? count;

  const _CategoryCard({required this.id, required this.label, required this.icon, this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = (count ?? 0) > 0;

    return PressableScale(
      enabled: enabled,
      onTap: enabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening "$label" needs the AI companion.'), duration: const Duration(seconds: 1)),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: enabled ? colors.primary : colors.onSurfaceVariant, size: 26),
            const Spacer(),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: enabled ? colors.onSurface : colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              count == null ? '—' : '$count',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showObjectsPage(BuildContext context, {Map<String, int> counts = const {}}) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: ObjectsPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, _) => ObjectsPage(counts: counts),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
