import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/filters/rating.dart';
import 'package:aves/model/filters/type.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/viewer/controls/notifications.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Composes a set of [CollectionFilter]s into a single dispatch.
///
/// Google-Photos-style narrowing: pick mime, rating floor, type filters,
/// then apply. The resulting filter set is dispatched through the same
/// `SelectFilterNotification` used by the info chips row, so it lands in
/// whatever collection view is listening.
class QueryComposerPage extends StatefulWidget {
  static const routeName = '/viewer/info/query_composer';

  const new({super.key});

  @override
  State<QueryComposerPage> createState() => _QueryComposerPageState();
}

class _QueryComposerPageState extends State<QueryComposerPage> {
  MimeFilter? _mime;
  int? _ratingMin;
  TypeFilter? _type;

  static final _mimes = <MimeFilter>[
    MimeFilter.image,
    MimeFilter.video,
  ];

  static const _ratings = <int>[1, 2, 3, 4, 5];

  static final _types = <TypeFilter>[
    TypeFilter.animated,
    TypeFilter.raw,
    TypeFilter.motionPhoto,
    TypeFilter.panorama,
    TypeFilter.slowMotion,
    TypeFilter.sphericalVideo,
    TypeFilter.hdr,
  ];

  Set<CollectionFilter> get _composed => {
        if (_mime != null) _mime!,
        if (_ratingMin != null) RatingFilter(_ratingMin!, op: RatingFilter.opOrGreater),
        if (_type != null) _type!,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final composed = _composed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose query'),
        actions: [
          TextButton(
            onPressed: composed.isEmpty
                ? null
                : () {
                    for (final f in composed) {
                      SelectFilterNotification(f).dispatch(context);
                    }
                    Navigator.of(context).maybePop();
                  },
            child: const Text('Apply'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _section(theme, colors, 'Media type'),
            _chipRow<MimeFilter>(
              items: _mimes,
              selected: _mime,
              label: (m) => m.mime.split('/').last,
              onSelect: (m) => setState(() => _mime = _mime == m ? null : m),
            ),
            const SizedBox(height: 16),
            _section(theme, colors, 'Minimum rating'),
            _chipRow<int>(
              items: _ratings,
              selected: _ratingMin,
              label: (r) => '$r★',
              onSelect: (r) => setState(() => _ratingMin = _ratingMin == r ? null : r),
            ),
            const SizedBox(height: 16),
            _section(theme, colors, 'Attributes'),
            _chipRow<TypeFilter>(
              items: _types,
              selected: _type,
              label: (t) => t.itemType,
              onSelect: (t) => setState(() => _type = _type == t ? null : t),
            ),
            const SizedBox(height: 24),
            if (composed.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
                ),
                child: Text(
                  'Applying ${composed.length} filter${composed.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, ColorScheme colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colors.onSurface),
      ),
    );
  }

  Widget _chipRow<T>({
    required List<T> items,
    required T? selected,
    required String Function(T) label,
    required ValueChanged<T> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;
        return PressableScale(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
            ),
            child: Text(
              label(item),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Future<void> showQueryComposerPage(BuildContext context) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: QueryComposerPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, __) => const QueryComposerPage(),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
