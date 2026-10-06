import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/viewer/info/cleaner_page.dart';
import 'package:aves/widgets/viewer/info/duplicates_page.dart';
import 'package:aves/widgets/viewer/info/people_page.dart';
import 'package:aves/widgets/viewer/info/objects_page.dart';
import 'package:aves/widgets/viewer/info/sync_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Hub that groups every AI-adjacent surface so users have one place
/// to find them, whatever their entry point.
class AiToolsPage extends StatelessWidget {
  static const routeName = '/viewer/info/ai_tools';

  final CollectionLens? collection;
  final AvesEntry entry;

  const new({super.key, this.collection, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI tools')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Tile(
              icon: Symbols.cleaning_services,
              title: 'Cleaner',
              subtitle: 'Large, screenshots, blurry, duplicates, old',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: CleanerPage.routeName),
                  builder: (context) => CleanerPage(entry: entry, collection: collection),
                ),
              ),
            ),
            _Tile(
              icon: Symbols.content_copy,
              title: 'Duplicates',
              subtitle: 'Find and review repeated items',
              onTap: () => showDuplicatesPage(context, entry, collection: collection),
            ),
            _Tile(
              icon: Symbols.face_6,
              title: 'People & faces',
              subtitle: 'Browse clusters of the people in your library',
              onTap: () => showPeoplePage(context),
            ),
            _Tile(
              icon: Symbols.category,
              title: 'Objects',
              subtitle: 'Browse by recognised object category',
              onTap: () => showObjectsPage(context),
            ),
            _Tile(
              icon: Symbols.translate,
              title: 'Translation',
              subtitle: 'Translate text recognised in photos',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open a photo and long-press the text button.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _Tile(
              icon: Symbols.shield_lock,
              title: 'Secure share',
              subtitle: 'Share without metadata',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open a photo and tap the shield action.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _Tile(
              icon: Symbols.cloud_sync,
              title: 'Backup & sync',
              subtitle: 'Google Photos sync settings',
              onTap: () => showSyncPage(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right, color: colors.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAiToolsPage(BuildContext context, AvesEntry entry, {CollectionLens? collection}) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: AiToolsPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, _) => AiToolsPage(entry: entry, collection: collection),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
