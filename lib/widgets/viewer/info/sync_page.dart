import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
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

  const new({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & sync')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PressableScale(
              onTap: () => showSyncSigninDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.cloud_sync, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Not connected', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                          Text(
                            'Tap to sign in and back up your library.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Symbols.chevron_right, color: colors.onSurfaceVariant, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              key: const Key('sync-backup-enabled'),
              value: _backupEnabled,
              onChanged: (v) => setState(() => _backupEnabled = v),
              title: const Text('Back up new media'),
              subtitle: const Text('Upload originals in the background'),
            ),
            SwitchListTile.adaptive(
              key: const Key('sync-albums'),
              value: _syncAlbums,
              onChanged: _backupEnabled ? (v) => setState(() => _syncAlbums = v) : null,
              title: const Text('Sync albums'),
              subtitle: const Text('Keep album membership aligned'),
            ),
            SwitchListTile.adaptive(
              key: const Key('sync-favourites'),
              value: _syncFavourites,
              onChanged: _backupEnabled ? (v) => setState(() => _syncFavourites = v) : null,
              title: const Text('Sync favourites'),
              subtitle: const Text('Mirror starred items'),
            ),
            const SizedBox(height: 16),
            PressableScale(
              enabled: _backupEnabled,
              onTap: _backupEnabled ? () {} : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.refresh, color: _backupEnabled ? colors.primary : colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sync now',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _backupEnabled ? colors.onSurface : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Last: never',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSyncPage(BuildContext context) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: SyncPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, _) => const SyncPage(),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
