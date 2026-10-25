import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:aves/widgets/viewer/info/sync_signin_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Google Photos sync surface.
///
/// UI shell. Wires up to nothing yet — the OAuth client and sync engine
/// live outside this repo. Every switch has a stable key so the actual
/// engine can hook in without UI changes.
class SyncPage extends StatefulWidget {
  static const routeName = '/viewer/info/sync';

  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _backupEnabled = false;
  bool _syncAlbums = true;
  bool _syncFavourites = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AvesScaffold(
      appBar: AppBar(title: const Text('Backup & sync')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    onTap: () => showSyncSigninDialog(context),
                    leading: Icon(Symbols.cloud_sync, color: colors.primary),
                    title: Text('Not connected', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      'Tap to sign in and back up your library.',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    trailing: Icon(Symbols.chevron_right, color: colors.onSurfaceVariant, size: 20),
                  ),
                  _divider(colors),
                  SwitchListTile.adaptive(
                    key: const Key('sync-backup-enabled'),
                    value: _backupEnabled,
                    onChanged: (v) => setState(() => _backupEnabled = v),
                    title: const Text('Back up new media'),
                    subtitle: const Text('Upload originals in the background'),
                  ),
                  _divider(colors),
                  SwitchListTile.adaptive(
                    key: const Key('sync-albums'),
                    value: _syncAlbums,
                    onChanged: _backupEnabled ? (v) => setState(() => _syncAlbums = v) : null,
                    title: const Text('Sync albums'),
                    subtitle: const Text('Keep album membership aligned'),
                  ),
                  _divider(colors),
                  SwitchListTile.adaptive(
                    key: const Key('sync-favourites'),
                    value: _syncFavourites,
                    onChanged: _backupEnabled ? (v) => setState(() => _syncFavourites = v) : null,
                    title: const Text('Sync favourites'),
                    subtitle: const Text('Mirror starred items'),
                  ),
                  _divider(colors),
                  ListTile(
                    enabled: _backupEnabled,
                    onTap: _backupEnabled ? () {} : null,
                    leading: Icon(Symbols.refresh, color: _backupEnabled ? colors.primary : colors.onSurfaceVariant),
                    title: Text(
                      'Sync now',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _backupEnabled ? colors.onSurface : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      'Last: never',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ColorScheme colors) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colors.outlineVariant.withValues(alpha: 0.3),
      );
}

Future<void> showSyncPage(BuildContext context) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: SyncPage.routeName),
      builder: (context) => const SyncPage(),
    ),
  );
}
