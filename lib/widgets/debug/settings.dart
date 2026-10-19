import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:aves/widgets/common/identity/highlight_title.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/countries_page.dart';
import 'package:aves/widgets/filter_grids/places_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class DebugSettingsSection extends StatefulWidget {
  const new({super.key});

  @override
  State<DebugSettingsSection> createState() => _DebugSettingsSectionState();
}

class _DebugSettingsSectionState extends State<DebugSettingsSection> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<Settings>(
      builder: (context, settings, child) {
        String toMultiline(Iterable? l) => l != null && l.isNotEmpty ? '\n${l.join('\n')}' : '$l';
        return AvesExpansionTile(
          title: 'Settings',
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'AI Companion'),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: _AiDiagnostics(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => settings.reset(includeInternalKeys: true),
                child: const Text('Reset (all store)'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => settings.reset(includeInternalKeys: false),
                child: const Text('Reset (user preferences)'),
              ),
            ),
            SwitchListTile(
              value: settings.canUseAnalysisService,
              onChanged: (v) => settings.canUseAnalysisService = v,
              title: const Text('canUseAnalysisService'),
            ),
            SwitchListTile(
              value: settings.aiSearchEnabled,
              onChanged: (v) => settings.aiSearchEnabled = v,
              title: const Text('aiSearchEnabled'),
              subtitle: const Text('replace search page with AI surface'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'catalogTimeZoneRawOffsetMillis': '${settings.catalogTimeZoneOffsetMillis}',
                  'collectionSelectionQuickActions': '${settings.collectionSelectionQuickActions}',
                  'viewerQuickActions': '${settings.viewerQuickActions}',
                  'pinnedFilters': toMultiline(settings.pinnedFilters),
                  'hiddenFilters': toMultiline(settings.hiddenFilters),
                  'deactivatedHiddenFilters': toMultiline(settings.deactivatedHiddenFilters),
                  'topEntryIds': '${settings.topEntryIds}',
                  'longPressTimeout': '${settings.longPressTimeout}',
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'Drawer'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'drawerTypeBookmarks': toMultiline(settings.drawerTypeBookmarks),
                  'drawerAlbumBookmarks': toMultiline(settings.drawerAlbumBookmarks),
                  'drawerPageBookmarks': toMultiline(settings.drawerPageBookmarks),
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'Groups'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'albumGroups': toMultiline(settings.albumGroups.entries),
                  'tagGroups': toMultiline(settings.tagGroups.entries),
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'History'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'recentSettingKeys': toMultiline(settings.recentSettingKeys),
                  'searchHistory': toMultiline(settings.searchHistory),
                  'recentDestinationAlbums': toMultiline(settings.recentDestinationAlbums),
                  'recentTags': toMultiline(settings.recentTags),
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'Locale'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'basic': '${settings.basicLocale}',
                  'resolved': '${settings.resolvedLocale}',
                  'aves': '${settings.avesLocale}',
                  'system': '${WidgetsBinding.instance.platformDispatcher.locales}',
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'Map'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'mapStyle': '${settings.mapStyle}',
                  'infoMapZoom': '${settings.infoMapZoom}',
                  'customMapStyles': toMultiline(settings.customMapStyles),
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: HighlightTitle(title: 'Tile Extent'),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: InfoRowGroup(
                info: {
                  'collection': '${settings.getTileExtent(CollectionPage.routeName)}',
                  'albums': '${settings.getTileExtent(AlbumListPage.routeName)}',
                  'countries': '${settings.getTileExtent(CountryListPage.routeName)}',
                  'places': '${settings.getTileExtent(PlaceListPage.routeName)}',
                  'tags': '${settings.getTileExtent(TagListPage.routeName)}',
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _AiDiagnostics extends StatefulWidget {
  const _AiDiagnostics();

  @override
  State<_AiDiagnostics> createState() => _AiDiagnosticsState();
}

class _AiDiagnosticsState extends State<_AiDiagnostics> {
  late Future<AiHealth> _healthFuture;
  final TextEditingController _cmd = TextEditingController(text: '@ocr');
  String _lastResult = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _healthFuture = aiService.health();
  }

  @override
  void dispose() {
    _cmd.dispose();
    super.dispose();
  }

  Future<void> _recheck() async {
    setState(() {
      _healthFuture = aiService.health(forceRefresh: true);
    });
  }

  Future<void> _run() async {
    if (_busy) return;
    final text = _cmd.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _lastResult = 'running...';
    });
    try {
      final reply = await aiService.chat(text);
      if (!mounted) return;
      final buf = StringBuffer()
        ..writeln('text:  ${reply.text}')
        ..writeln('ids:   ${reply.entryIds}')
        ..writeln('error: ${reply.error}')
        ..writeln('code:  ${reply.errorCode}');
      setState(() => _lastResult = buf.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastResult = 'threw: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final containerDecoration = BoxDecoration(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: containerDecoration,
          child: FutureBuilder<AiHealth>(
            future: _healthFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Text('querying companion...');
              }
              final h = snap.data;
              if (h == null) return const Text('no result');
              final healthText = [
                'installed:    ${h.installed}',
                'connected:    ${h.connected}',
                'apiVersion:   ${h.apiVersion}',
                'package:      ${h.companionPackage ?? '-'}',
                'capabilities: ${h.capabilities.isEmpty ? '-' : h.capabilities.join(', ')}',
                if (h.error != null) 'error:        ${h.error}',
              ].join('\n');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: InfoRowGroup(
                        info: {
                          'installed': '${h.installed}',
                          'connected': '${h.connected}',
                          'apiVersion': '${h.apiVersion}',
                          'package': h.companionPackage ?? '-',
                          'capabilities': h.capabilities.isEmpty ? '-' : h.capabilities.join(', '),
                          if (h.error != null) 'error': h.error!,
                        },
                      )),
                      IconButton(
                        tooltip: 'Copy health',
                        icon: const Icon(Symbols.content_copy, size: 18),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: healthText));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Health copied'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Recheck',
                        icon: const Icon(Symbols.refresh, size: 18),
                        onPressed: _recheck,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: containerDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Chat probe (no entry media attached)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextField(
                controller: _cmd,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '@ocr, /find dog, ...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _run,
                    child: Text(_busy ? 'running...' : 'Run'),
                  ),
                  const Spacer(),
                  if (_lastResult.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _lastResult));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Result copied'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Symbols.content_copy, size: 16),
                      label: const Text('Copy'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _lastResult.isEmpty ? '(no result yet)' : _lastResult,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
