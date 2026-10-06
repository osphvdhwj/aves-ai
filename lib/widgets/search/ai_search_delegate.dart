import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/ai/prompt_library.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/model/ai/prompt_service.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/widgets/common/search/delegate.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AiSearchDelegate extends AvesSearchDelegate {
  final String? initialText;

  List<AiPrompt> _rotating = const [];
  List<String> _dynamic = const [];

  new({
    required super.searchFieldLabel,
    required super.searchFieldStyle,
    super.canPop,
    this.initialText,
  }) : super(routeName: SearchPage.routeName) {
    query = initialText ?? '';
    _rotating = PromptLibrary.pick(6);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_dynamic.isEmpty) {
      try {
        final source = context.read<CollectionSource>();
        _dynamic = AiPromptService(source).buildDynamicPrompts(max: 4);
      } catch (_) {
        _dynamic = const [];
      }
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask AI',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search your library with words, commands and modes.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── faces ─────────────────────────────────────────
          const _FaceRow(),

          const SizedBox(height: 28),

          // ── hero card ─────────────────────────────────────
          _HeroCard(
            title: 'My best pictures',
            subtitle: 'Curated from your top shots',
            onTap: () => _onPrompt(context, 'My best pictures'),
          ),

          const SizedBox(height: 24),

          // ── history ───────────────────────────────────────
          if (settings.aiSearchHistory.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _sectionTitle(theme, 'Recent')),
                TextButton(
                  onPressed: () {
                    settings.aiSearchHistory = const [];
                    // force rebuild
                    final v = query;
                    query = v.isEmpty ? ' ' : v;
                    query = v;
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _HistoryChips(
              queries: settings.aiSearchHistory,
              onTap: (text) => _onPrompt(context, text),
            ),
            const SizedBox(height: 24),
          ],

          // ── try asking ────────────────────────────────────
          _sectionTitle(theme, 'Try asking'),
          const SizedBox(height: 12),
          _PromptGrid(
            prompts: [
              ..._dynamic.map((p) => _GridPrompt(p, Icons.auto_awesome)),
              ..._rotating.map((p) => _GridPrompt(p.text, _iconForCategory(p.category))),
            ],
            onTap: (text) => _onPrompt(context, text),
          ),

          const SizedBox(height: 24),

          // ── quick actions ─────────────────────────────────
          _sectionTitle(theme, 'Quick actions'),
          const SizedBox(height: 12),
          _QuickActions(onTap: (text) => _onPrompt(context, text)),
        ],
      ),
    );
  }

  @override
  Future<AiChatReply>? _resultFuture;
  String? _lastQuery;

  Widget buildResults(BuildContext context) {
    final currentQuery = query.trim();
    if (currentQuery != _lastQuery) {
      _lastQuery = currentQuery;
      _resultFuture = _runQuery(context, currentQuery);
    }
    return FutureBuilder<AiChatReply>(
      future: _resultFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final reply = snap.data;
        if (reply == null) {
          return const Center(child: Text('No reply'));
        }
        if (reply.error != null) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: ${reply.error}')));
        }
        final source = context.read<CollectionSource>();
        final entries = reply.entryIds
            .map(source.getEntryById)
            .whereType<AvesEntry>()
            .toList();
        if (entries.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(reply.text.isEmpty ? 'No results' : reply.text)));
        }
        return _ResultGrid(entries: entries);
      },
    );
  }

  Future<AiChatReply> _runQuery(BuildContext context, String q) async {
    final source = context.read<CollectionSource>();
    final ids = source.visibleEntries.take(200).map((e) => e.id).toList();
    return aiService.chat(q, entryIds: ids);
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  void _onPrompt(BuildContext context, String text) {
    query = text;
    showResults(context);
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'people':
        return Icons.people_outline;
      case 'places':
        return Icons.place_outlined;
      case 'nature':
        return Icons.eco_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'animals':
        return Icons.pets_outlined;
      case 'activity':
        return Icons.directions_run_outlined;
      case 'event':
        return Icons.celebration_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'quality':
        return Icons.high_quality_outlined;
      case 'time':
        return Icons.schedule_outlined;
      case 'mood':
        return Icons.emoji_emotions_outlined;
      case 'translate':
        return Icons.translate;
      case 'objects':
        return Icons.category_outlined;
      case 'clean':
        return Icons.cleaning_services_outlined;
      default:
        return Icons.auto_awesome;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// hero card
// ─────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const new({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer,
              colors.tertiaryContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.onPrimaryContainer.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colors.onPrimaryContainer,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// prompt grid
// ─────────────────────────────────────────────────────────────
class _GridPrompt {
  final String text;
  final IconData icon;

  const _GridPrompt(this.text, this.icon);
}

class _PromptGrid extends StatelessWidget {
  final List<_GridPrompt> prompts;
  final ValueChanged<String> onTap;

  const new({
    required this.prompts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: prompts.length,
      itemBuilder: (context, i) {
        final p = prompts[i];
        return _PromptTile(
          text: p.text,
          icon: p.icon,
          onTap: () => onTap(p.text),
        );
      },
    );
  }
}

class _PromptTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const new({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// quick actions
// ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onTap;

  /// Derived from [AiCommands.all] so the palette stays in sync with the
  /// command registry.
  static List<(String, IconData)> get _actions =>
      AiCommands.all.map((c) => (c.token, _iconForCommand(c.token))).toList();

  static IconData _iconForCommand(String token) => switch (token) {
    '/find' => Icons.search,
    '/dup' => Icons.copy_all_outlined,
    '/blur' => Icons.blur_on_outlined,
    '/receipt' => Icons.receipt_long_outlined,
    '/clean' => Icons.cleaning_services_outlined,
    '/translate' => Icons.translate,
    '/objects' => Icons.category_outlined,
    '/faces' => Icons.face_outlined,
    '@deep' => Icons.psychology_outlined,
    '@fast' => Icons.bolt_outlined,
    '@ocr' => Icons.text_fields_outlined,
    '@person' => Icons.person_outline,
    '@like' => Icons.favorite_outline,
    _ => Icons.auto_awesome,
  };

  const new({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _actions.map((a) {
          final (token, icon) = a;
          return PressableScale(
            onTap: () => onTap(token),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    token,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// face row
// ─────────────────────────────────────────────────────────────
class _FaceRow extends StatelessWidget {
  static const _circleDim = 72.0;

  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [
      colors.primaryContainer,
      colors.secondaryContainer,
      colors.tertiaryContainer,
    ];
    final fgPalette = [
      colors.onPrimaryContainer,
      colors.onSecondaryContainer,
      colors.onTertiaryContainer,
    ];

    return SizedBox(
      height: _circleDim + 20,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 9,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i == 8) {
            return Column(
              children: [
                PressableScale(
                  onTap: () => _notify(context, 'more'),
                  child: Container(
                    width: _circleDim,
                    height: _circleDim,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceContainerHighest,
                      border: Border.all(color: colors.outlineVariant, width: 1.5),
                    ),
                    child: Icon(Icons.add, color: colors.onSurfaceVariant, size: 28),
                  ),
                ),
                const SizedBox(height: 4),
                Text('More', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              ],
            );
          }

          final isFirst = i == 0;
          return Column(
            children: [
              PressableScale(
                onTap: () => _notify(context, isFirst ? 'me' : 'person ${i + 1}'),
                child: Container(
                  width: _circleDim,
                  height: _circleDim,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette[i % palette.length],
                    border: isFirst
                        ? Border.all(color: colors.primary, width: 2.5)
                        : null,
                  ),
                  child: Icon(
                    isFirst ? Icons.person : Icons.person_outline,
                    color: fgPalette[i % fgPalette.length],
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFirst ? 'Me' : 'Person ${i + 1}',
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }

  void _notify(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), duration: const Duration(seconds: 1)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// result grid
// ─────────────────────────────────────────────────────────────
class _ResultGrid extends StatelessWidget {
  final List<AvesEntry> entries;

  const new({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return PressableScale(
          onTap: () => _openViewer(context, entry),
          scale: 0.92,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: entry.getThumbnail(extent: 256),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, size: 24),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openViewer(BuildContext context, AvesEntry entry) {
    Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: EntryViewerPage.routeName),
        builder: (_) => EntryViewerPage(initialEntry: entry),
      ),
    );
  }
}

class _HistoryChips extends StatelessWidget {
  final List<String> queries;
  final ValueChanged<String> onTap;

  const new({
    super.key,
    required this.queries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: queries.map((q) {
          return PressableScale(
            onTap: () => onTap(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      q,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
