import 'dart:convert';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Object category browser, powered by the companion's YOLO detector.
///
/// Opening the page runs `/objects *` — one detection pass over the
/// supplied entries — and renders a per-label histogram. Tapping a label
/// opens the photos it was detected on. Requires the companion; without
/// it the page shows an honest empty state.
class ObjectsPage extends StatefulWidget {
  static const routeName = '/viewer/info/objects';

  /// Entries the histogram runs over. Capped by the caller: detection is
  /// one YOLO inference per photo.
  final List<AvesEntry> entries;

  const ObjectsPage({super.key, this.entries = const []});

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage> {
  List<_ObjectLabel>? _labels;
  bool _companionUnavailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!await aiService.hasCapability('objects')) {
        if (mounted) setState(() => _companionUnavailable = true);
        return;
      }
      final payload = widget.entries.take(200).toList();
      final reply = await aiService.chat(
        '/objects *',
        entryIds: payload.map((e) => e.id).toList(),
        entries: AiService.entriesPayload(payload),
      );
      if (!mounted) return;
      final error = reply.error;
      if (error != null && error.isNotEmpty) {
        setState(() => _error = error);
        return;
      }
      final labels = <_ObjectLabel>[];
      final extra = reply.extra;
      if (extra != null && extra.isNotEmpty) {
        final decoded = jsonDecode(extra);
        if (decoded is Map<String, dynamic>) {
          final list = decoded['labels'];
          if (list is List) {
            final byId = {for (final e in payload) e.id: e};
            for (final item in list) {
              if (item is! Map<String, dynamic>) continue;
              final label = item['label'] as String?;
              final count = (item['count'] as num?)?.toInt() ?? 0;
              if (label == null || count <= 0) continue;
              final ids = (item['ids'] as List?)?.cast<int>() ?? const <int>[];
              final entries = ids.map((id) => byId[id]).whereType<AvesEntry>().toList();
              if (entries.isEmpty) continue;
              labels.add(_ObjectLabel(label: label, entries: entries));
            }
          }
        }
      }
      setState(() => _labels = labels);
    } catch (e, s) {
      await reportService.recordError(e, s);
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return AvesScaffold(
      appBar: AppBar(title: const Text('Objects')),
      body: SafeArea(
        child: _companionUnavailable
            ? const StatusView(
                icon: Symbols.category,
                title: 'Objects needs the AI companion',
                subtitle: 'Install and connect AVES+ Tools, then reopen this page to scan your photos for objects.',
              )
            : _error != null
                ? StatusView(
                    icon: AIcons.error,
                    isError: true,
                    title: 'Object scan failed',
                    subtitle: _error,
                  )
                : labels == null
                    ? const Center(child: CircularProgressIndicator())
                    : labels.isEmpty
                        ? StatusView(
                            icon: Symbols.category,
                            title: 'No objects recognised',
                            subtitle: 'Scanned ${widget.entries.length} photos with the on-device detector.',
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.15,
                            ),
                            itemCount: labels.length,
                            itemBuilder: (context, index) {
                              final l = labels[index];
                              return _CategoryCard(label: l);
                            },
                          ),
      ),
    );
  }
}

class _ObjectLabel {
  final String label;
  final List<AvesEntry> entries;

  const _ObjectLabel({required this.label, required this.entries});
}

class _CategoryCard extends StatelessWidget {
  final _ObjectLabel label;

  const _CategoryCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PressableScale(
      onTap: () => _openResults(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconFor(label.label), color: colors.primary, size: 26),
            const Spacer(),
            Text(
              label.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${label.entries.length}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _openResults(BuildContext context) {
    Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/viewer/info/objects/${label.label}'),
        builder: (context) => _ObjectsResultPage(label: label),
      ),
    );
  }

  static IconData _iconFor(String label) => switch (label) {
    'person' => Symbols.people,
    'dog' || 'cat' || 'bird' || 'horse' || 'sheep' || 'cow' => Symbols.pets,
    'car' || 'truck' || 'bus' || 'motorcycle' || 'bicycle' => Symbols.directions_car,
    'chair' || 'couch' || 'bed' => Symbols.chair,
    'cup' || 'bottle' || 'wine glass' => Symbols.local_cafe,
    'laptop' || 'cell phone' || 'tv' || 'keyboard' || 'mouse' => Symbols.devices,
    'book' => Symbols.book,
    'clock' => Symbols.schedule,
    _ => Symbols.category,
  };
}

/// Grid of the photos a label was detected on.
class _ObjectsResultPage extends StatelessWidget {
  final _ObjectLabel label;

  const _ObjectsResultPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return AvesScaffold(
      appBar: AppBar(
        title: Text(
          label.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: label.entries.length,
          itemBuilder: (context, index) {
            final e = label.entries[index];
            return PressableScale(
              onTap: () {
                // Personalization signal for the companion's auto-training:
                // the user picked this detection for this label.
                aiService.feedback(type: 'find_like', entryId: e.id, query: '/objects ${label.label}');
                Navigator.maybeOf(context)?.push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: EntryViewerPage.routeName),
                    builder: (_) => EntryViewerPage(initialEntry: e),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                child: Image(
                  image: e.getThumbnail(extent: 256),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> showObjectsPage(BuildContext context, {List<AvesEntry> entries = const []}) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: ObjectsPage.routeName),
      builder: (context) => ObjectsPage(entries: entries),
    ),
  );
}
