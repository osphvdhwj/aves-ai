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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: FutureBuilder<AiHealth>(
      future: aiService.health(),
      builder: (context, snap) {
        final theme = Theme.of(context);
        if (snap.connectionState != ConnectionState.done) {
          return Text('Checking companion...', style: theme.textTheme.bodyMedium);
        }
        final h = snap.data;
        if (h == null) {
          return Text('No result', style: theme.textTheme.bodyMedium);
        }
        final installed = h.installed;
        final connected = h.connected;
        final color = connected ? theme.colorScheme.primary : theme.colorScheme.error;
        final status = connected
            ? 'Connected  ·  v${h.apiVersion ?? '?'}  ·  ${h.capabilities.join(', ')}'
            : installed
                ? 'Installed but not connected'
                : 'Companion not installed';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(connected ? Symbols.check_circle : Symbols.info, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title(context), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(status, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        );
      },
    ),
  );
}
