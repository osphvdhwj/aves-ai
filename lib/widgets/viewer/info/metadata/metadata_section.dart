import 'dart:async';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/info.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/identity/buttons/outlined_button.dart';
import 'package:aves/widgets/viewer/info/metadata/metadata_dir.dart';
import 'package:aves/widgets/viewer/info/metadata/metadata_dir_tile.dart';
import 'package:aves/widgets/viewer/info/metadata/tv_page.dart';
import 'package:material_ui/material_ui.dart';

class MetadataSectionSliver extends StatefulWidget {
  final AvesEntry entry;
  final ValueNotifier<Map<String, MetadataDirectory>> metadataNotifier;

  const new({
    super.key,
    required this.entry,
    required this.metadataNotifier,
  });

  @override
  State<StatefulWidget> createState() => _MetadataSectionSliverState();
}

class _MetadataSectionSliverState extends State<MetadataSectionSliver> {
  final ValueNotifier<String?> _expandedDirectoryNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);

  AvesEntry get entry => widget.entry;

  ValueNotifier<Map<String, MetadataDirectory>> get metadataNotifier => widget.metadataNotifier;

  @override
  void initState() {
    super.initState();
    _registerWidget(widget);
    _onEntryChanged();
  }

  @override
  void didUpdateWidget(covariant MetadataSectionSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
    if (oldWidget.entry != widget.entry) {
      _onEntryChanged();
    }
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    _expandedDirectoryNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _registerWidget(MetadataSectionSliver widget) {
    widget.entry.metadataChangeNotifier.addListener(_getMetadata);
  }

  void _unregisterWidget(MetadataSectionSliver widget) {
    widget.entry.metadataChangeNotifier.removeListener(_getMetadata);
  }

  @override
  Widget build(BuildContext context) {
    // Use a `Column` inside a `SliverToBoxAdapter` instead of a `SliverList`
    // so the tiles rebuild cleanly when the entry changes without
    // triggering dispose/reinit of other sections (e.g. maps).
    return SliverToBoxAdapter(
      child: NotificationListener<ScrollNotification>(
        // cancel notification bubbling so that the info page
        // does not misinterpret content scrolling for page scrolling
        onNotification: (notification) => true,
        child: ValueListenableBuilder<Map<String, MetadataDirectory>>(
          valueListenable: metadataNotifier,
          builder: (context, metadata, child) {
            Widget content;
            if (metadata.isEmpty) {
              content = ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, loading, child) {
                  if (!loading) return const SizedBox();
                  final theme = Theme.of(context);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Reading metadata…',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              content = Column(
                children: settings.useTvLayout
                      ? [
                          const SizedBox(height: 16),
                          AvesOutlinedButton(
                            label: MaterialLocalizations.of(context).moreButtonTooltip,
                            onPressed: () {
                              Navigator.maybeOf(context)?.push(
                                MaterialPageRoute(
                                  settings: const RouteSettings(name: TvMetadataPage.routeName),
                                  builder: (context) => TvMetadataPage(
                                    entry: entry,
                                    metadata: metadata,
                                  ),
                                ),
                              );
                            },
                          ),
                        ]
                      : [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Text(
                              'Metadata',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          ...metadata.entries.map(
                            (kv) => MetadataDirTile(
                              entry: entry,
                              title: kv.key,
                              dir: kv.value,
                              expandedDirectoryNotifier: _expandedDirectoryNotifier,
                            ),
                          ),
                        ],
              );
            }

            return content;
          },
        ),
      ),
    );
  }

  void _onEntryChanged() {
    metadataNotifier.value = {};
    _getMetadata();
  }

  Future<void> _getMetadata() async {
    _isLoadingNotifier.value = true;
    try {
      final titledDirectories = await entry.getMetadataDirectories(context);
      if (!mounted) return;
      metadataNotifier.value = Map.fromEntries(titledDirectories);
      _expandedDirectoryNotifier.value = null;
    } finally {
      if (mounted) _isLoadingNotifier.value = false;
    }
  }
}
