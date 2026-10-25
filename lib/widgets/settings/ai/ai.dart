import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/settings/common/tile_leading.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AiSection extends SettingsSection {
  @override
  String get key => 'ai';

  @override
  Widget icon(BuildContext context) => SettingsTileLeading(
    icon: AIcons.help,
    color: context.select<AvesColorsData, Color>((v) => v.accessibility),
  );

  @override
  String title(BuildContext context) => 'AI';

  @override
  Future<List<SettingsTile>> tiles(BuildContext context) => Future.value([
    SettingsTileAiEnable(),
    SettingsTileAiStatus(),
    SettingsTileShowGooglePhotosBackup(),
  ]);
}

class SettingsTileShowGooglePhotosBackup extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.showGooglePhotosBackupKey];

  @override
  String title(BuildContext context) => 'Google Photos backup status';

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.showGooglePhotosBackup,
    onChanged: (v) => settings.showGooglePhotosBackup = v,
    title: title,
    subtitle: (_) => 'Show a "Backed up" row in the info page when the companion reports Google Photos status',
  );
}

class SettingsTileAiEnable extends SettingsTile {
  @override
  List<String> get settingKeys => [SettingKeys.aiSearchEnabledKey];

  @override
  String title(BuildContext context) => 'Enable AI search';

  @override
  Widget build(BuildContext context) => SettingsSwitchListTile(
    selector: (context, s) => s.aiSearchEnabled,
    onChanged: (v) => settings.aiSearchEnabled = v,
    title: title,
    subtitle: (_) => 'Replace search with the AI surface',
  );
}

class SettingsTileAiStatus extends SettingsTile {
  @override
  List<String> get settingKeys => const [];

  @override
  String title(BuildContext context) => 'Companion status';

  @override
  Widget build(BuildContext context) => const _AiStatusTileBody();
}

class _AiStatusTileBody extends StatefulWidget {
  const _AiStatusTileBody();

  @override
  State<_AiStatusTileBody> createState() => _AiStatusTileBodyState();
}

class _AiStatusTileBodyState extends State<_AiStatusTileBody> {
  late Future<AiHealth> _future;

  @override
  void initState() {
    super.initState();
    _future = aiService.health();
  }

  void _recheck() {
    setState(() {
      _future = aiService.health(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<AiHealth>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final h = snap.data;
        final connected = h?.connected == true;
        final installed = h?.installed == true;
        final pkg = h?.companionPackage;
        final subtitle = loading
            ? 'Checking companion…'
            : h == null
                ? 'No result'
                : connected
                    ? 'Connected  ·  v${h.apiVersion ?? '?'}  ·  ${h.capabilities.join(', ')}${pkg != null ? '\n$pkg' : ''}'
                    : installed
                        ? 'Installed but not connected${pkg != null ? '  ·  $pkg' : ''}'
                        : 'Companion not installed';
        return ListTile(
          leading: Icon(
            loading
                ? Symbols.autorenew
                : connected
                    ? Symbols.check_circle
                    : Symbols.info,
            color: connected ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          title: Text(
            'Companion status',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: TextButton(
            onPressed: _recheck,
            child: const Text('Recheck'),
          ),
        );
      },
    );
  }
}
