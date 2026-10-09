import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/viewer/info/cleaner_page.dart';
import 'package:aves/widgets/viewer/info/duplicates_page.dart';
import 'package:aves/widgets/viewer/info/people_page.dart';
import 'package:aves/widgets/viewer/info/objects_page.dart';
import 'package:aves/widgets/viewer/info/memories_page.dart';
import 'package:aves/widgets/viewer/info/query_composer_page.dart';
import 'package:aves/widgets/ai/ai_chat_page.dart';
import 'package:aves/widgets/viewer/info/sync_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Hub that groups every AI-adjacent surface so users have one place
/// to find them, whatever their entry point.
class AiToolsPage extends StatefulWidget {
  static const routeName = '/viewer/info/ai_tools';

  final CollectionLens? collection;
  final AvesEntry entry;

  const new({super.key, this.collection, required this.entry});

  @override
  State<AiToolsPage> createState() => _AiToolsPageState();
}

class _AiToolsPageState extends State<AiToolsPage> {
  late Future<AiHealth> _healthFuture;

  AvesEntry get entry => widget.entry;
  CollectionLens? get collection => widget.collection;

  @override
  void initState() {
    super.initState();
    _healthFuture = aiService.health();
  }

  bool _has(AiHealth? h, String capability) => h?.connected == true && h!.has(capability);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI tools')),
      body: SafeArea(
        child: FutureBuilder<AiHealth>(
          future: _healthFuture,
          builder: (context, healthSnapshot) {
            final health = healthSnapshot.data;
            final connected = health?.connected == true;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                ..._buildTiles(context, health),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTiles(BuildContext context, AiHealth? health) {
    final needsOcr = _has(health, 'ocr');
    final needsFaces = _has(health, 'person') || _has(health, 'faces');
    final needsObjects = _has(health, 'objects');
    final needsChat = health?.connected == true;

    return [
      _Tile(
        icon: Symbols.auto_awesome,
        title: 'Memories',
        subtitle: 'Auto-curated collections from your library',
        onTap: () => showMemoriesPage(context, entry, collection: collection),
      ),
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
        icon: Symbols.filter_alt,
        title: 'Compose query',
        subtitle: 'Build a filter from mime, rating, attributes',
        onTap: () => showQueryComposerPage(context),
      ),
      _Tile(
        icon: Symbols.face_6,
        title: 'People & faces',
        subtitle: needsFaces ? 'Browse clusters of the people in your library' : 'Needs companion with face capability',
        onTap: needsFaces ? () => showPeoplePage(context) : null,
      ),
      _Tile(
        icon: Symbols.category,
        title: 'Objects',
        subtitle: needsObjects ? 'Browse by recognised object category' : 'Needs companion with objects capability',
        onTap: needsObjects ? () => showObjectsPage(context) : null,
      ),
      _Tile(
        icon: Symbols.translate,
        title: 'Translation',
        subtitle: needsOcr ? 'Translate text recognised in photos' : 'Needs companion with OCR capability',
        onTap: needsOcr
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Open a photo and long-press the text button.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : null,
      ),
      _Tile(
        icon: Symbols.forum,
        title: 'Ask AI about this photo',
        subtitle: needsChat ? 'Open a chat about this image' : 'Needs companion connected',
        onTap: needsChat
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: AiChatPage.routeName),
                    builder: (context) => AiChatPage(entry: entry),
                  ),
                )
            : null,
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
    ];
  }
}

class _CompanionBanner extends StatelessWidget {
  final AiHealth? health;

  const _CompanionBanner({required this.health});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final installed = health?.installed == true;
    final text = installed
        ? 'Companion installed but not connected. ML tools are disabled.'
        : 'AVES+ Tools not installed. ML tools are disabled; local tools still work.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
        ),
        child: Row(
          children: [
            Icon(installed ? Symbols.info : Symbols.download, color: colors.onErrorContainer, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: colors.onErrorContainer)),
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
  final VoidCallback? onTap;

  const _Tile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        enabled: enabled,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? colors.surfaceContainerHigh : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
          ),
          child: Row(
            children: [
              Icon(icon, color: enabled ? colors.primary : colors.onSurfaceVariant.withValues(alpha: .4)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled ? colors.onSurfaceVariant : colors.onSurfaceVariant.withValues(alpha: .7),
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(Symbols.chevron_right, color: colors.onSurfaceVariant, size: 20)
              else
                Icon(Symbols.lock, color: colors.onSurfaceVariant.withValues(alpha: .5), size: 18),
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
