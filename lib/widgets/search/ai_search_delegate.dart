import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/ai/prompt_library.dart';
import 'package:aves/theme/m3e_tokens.dart';
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
import 'package:material_symbols_icons/symbols.dart';
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
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

          // ── saved ─────────────────────────────────────────
          if (settings.savedSearches.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _sectionTitle(theme, 'Saved')),
                TextButton(
                  onPressed: () {
                    settings.savedSearches = const [];
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
              queries: settings.savedSearches,
              onTap: (text) => _onPrompt(context, text),
            ),
            const SizedBox(height: 24),
          ],

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
              ..._dynamic.map((p) => _GridPrompt(p, Symbols.auto_awesome)),
              ..._rotating.map((p) => _GridPrompt(p.text, _iconForCategory(p.category))),
            ],
            onTap: (text) => _onPrompt(context, text),
          ),

          const SizedBox(height: 24),

          // ── quick actions ─────────────────────────────────
          _sectionTitle(theme, 'Commands & modes'),
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
          return const _LoadingState();
        }
        final reply = snap.data;
        if (reply == null) {
          return _ErrorState(
            message: 'No reply from the assistant.',
            onRetry: () => _retry(context),
          );
        }
        if (reply.isModelMissing) {
          return _ErrorState(
            message: 'The AVES+ Tools companion needs a model it does not have yet.',
            onRetry: () => _retry(context),
          );
        }
        if (reply.isUnsupported) {
          return _ErrorState(
            message: 'This companion build does not support AI search. Update AVES+ Tools.',
            onRetry: () => _retry(context),
          );
        }
        if (reply.error != null) {
          return _ErrorState(
            message: reply.error!,
            onRetry: () => _retry(context),
          );
        }
        final source = context.read<CollectionSource>();
        final entries = reply.entryIds
            .map(source.getEntryById)
            .whereType<AvesEntry>()
            .toList();
        if (entries.isEmpty) {
          return _EmptyResults(
            text: reply.text,
            onPrompt: (p) => _onPrompt(context, p),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResultsHeader(count: entries.length),
            _SaveQueryBar(query: currentQuery),
            Expanded(child: _ResultGrid(entries: entries)),
          ],
        );
      },
    );
  }

  Future<AiChatReply> _runQuery(BuildContext context, String q) async {
    final source = context.read<CollectionSource>();
    final sample = source.visibleEntries.take(200).toList();
    final ids = sample.map((e) => e.id).toList();
    return aiService.chat(
      q,
      entryIds: ids,
      entries: AiService.entriesPayload(sample),
    );
  }

  void _retry(BuildContext context) {
    _lastQuery = null;
    _resultFuture = null;
    showResults(context);
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
        return Symbols.people;
      case 'places':
        return Symbols.place;
      case 'nature':
        return Symbols.eco;
      case 'food':
        return Symbols.restaurant;
      case 'animals':
        return Symbols.pets;
      case 'activity':
        return Symbols.directions_run;
      case 'event':
        return Symbols.celebration;
      case 'document':
        return Symbols.description;
      case 'quality':
        return Symbols.high_quality;
      case 'time':
        return Symbols.schedule;
      case 'mood':
        return Symbols.emoji_emotions;
      case 'translate':
        return Symbols.translate;
      case 'objects':
        return Symbols.category;
      case 'clean':
        return Symbols.cleaning_services;
      default:
        return Symbols.auto_awesome;
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final m3e = context.m3e;
    final ink = colors.onPrimaryContainer;

    return PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(m3e.shapeExtraLarge),
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primaryContainer, colors.tertiaryContainer],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ink.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ink.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(m3e.shapeLarge + 4),
                          ),
                          child: Icon(Symbols.auto_awesome, color: ink, size: 32),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'Try it',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Symbols.arrow_outward, size: 18, color: ink),
                      ],
                    ),
                  ],
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
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
    final m3e = context.m3e;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(m3e.shapeExtraLarge - 6),
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(m3e.shapeLarge - 2),
                  ),
                  child: Icon(icon, size: 22, color: colors.onPrimaryContainer),
                ),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Symbols.north_east,
                size: 14,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
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

  static List<(String, IconData)> get _actions =>
      AiCommands.all.map((c) => (c.token, _iconForCommand(c.token))).toList();

  static IconData _iconForCommand(String token) => switch (token) {
    '/find' => Symbols.search,
    '/dup' => Symbols.copy_all,
    '/blur' => Symbols.blur_on,
    '/receipt' => Symbols.receipt_long,
    '/clean' => Symbols.cleaning_services,
    '/translate' => Symbols.translate,
    '/objects' => Symbols.category,
    '/faces' => Symbols.face,
    '@deep' => Symbols.psychology,
    '@fast' => Symbols.bolt,
    '@ocr' => Symbols.text_fields,
    '@person' => Symbols.person,
    '@like' => Symbols.favorite,
    _ => Symbols.auto_awesome,
  };

  const new({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m3e = context.m3e;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (token, icon) = _actions[i];
          final isMode = token.startsWith('@');
          final tint = isMode ? colors.tertiary : colors.primary;
          return PressableScale(
            onTap: () => onTap(token),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(m3e.shapeExtraLarge - 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: tint),
                  const SizedBox(width: 8),
                  Text(
                    token,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// face row
// ─────────────────────────────────────────────────────────────
class _Person {
  final String id;
  final String label;

  const _Person({required this.id, required this.label});

  /// Fallback set shown until face-cluster data is wired through ai_service.
  static const stubs = <_Person>[
    _Person(id: 'me', label: 'Me'),
    _Person(id: 'p2', label: 'Person 2'),
    _Person(id: 'p3', label: 'Person 3'),
    _Person(id: 'p4', label: 'Person 4'),
    _Person(id: 'p5', label: 'Person 5'),
    _Person(id: 'p6', label: 'Person 6'),
    _Person(id: 'p7', label: 'Person 7'),
    _Person(id: 'p8', label: 'Person 8'),
  ];
}

/// Data-driven people rail. Pass [people] once face clusters are available;
/// otherwise the stub list is rendered. Kept as [_FaceRow] so existing call
/// sites do not need to change.
class _FaceRow extends StatelessWidget {
  final List<_Person>? people;
  final ValueChanged<_Person>? onPick;
  final VoidCallback? onSeeAll;

  static const _circleDim = 76.0;

  const new({super.key, this.people, this.onPick, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final list = people ?? _Person.stubs;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'People',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll ?? () => _notify(context, 'see all'),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _circleDim + 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              if (i == list.length) {
                return _PersonCircle(
                  label: 'Add',
                  icon: Symbols.add,
                  bg: colors.surfaceContainerHighest,
                  fg: colors.onSurfaceVariant,
                  borderColor: colors.outlineVariant,
                  onTap: () => _notify(context, 'add person'),
                );
              }
              final p = list[i];
              final isFirst = i == 0;
              return _PersonCircle(
                label: p.label,
                icon: Symbols.person,
                bg: palette[i % palette.length],
                fg: fgPalette[i % fgPalette.length],
                borderColor: isFirst ? colors.primary : null,
                borderWidth: isFirst ? 2.5 : 1.5,
                onTap: () => (onPick ?? (_) => _notify(context, p.label)).call(p),
              );
            },
          ),
        ),
      ],
    );
  }

  void _notify(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), duration: const Duration(seconds: 1)),
    );
  }
}

class _PersonCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback onTap;

  const new({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressableScale(
          onTap: onTap,
          child: Container(
            width: _FaceRow._circleDim,
            height: _FaceRow._circleDim,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: borderWidth),
            ),
            child: Icon(icon, color: fg, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// results header
// ─────────────────────────────────────────────────────────────
class _ResultsHeader extends StatelessWidget {
  final int count;

  const new({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final m3e = context.m3e;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Icon(Symbols.auto_awesome, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            'Results',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(m3e.shapeSmall + 2),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
    final colors = Theme.of(context).colorScheme;
    final m3e = context.m3e;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return PressableScale(
          onTap: () => _openViewer(context, entry),
          scale: 0.94,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(m3e.shapeLarge + 2),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(m3e.shapeLarge + 2),
              child: Image(
                image: entry.getThumbnail(extent: 256),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: colors.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(Symbols.broken_image, size: 22, color: colors.onSurfaceVariant),
                ),
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

// ─────────────────────────────────────────────────────────────
// loading / error / empty
// ─────────────────────────────────────────────────────────────
class _LoadingState extends StatefulWidget {
  const new({super.key});

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m3e = context.m3e;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Row(
            children: [
              Icon(Symbols.auto_awesome, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Searching…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: 9,
            itemBuilder: (context, i) => FadeTransition(
              opacity: Tween<double>(begin: 0.45, end: 0.85).animate(_ctl),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(m3e.shapeLarge + 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const new({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Symbols.error, size: 32, color: colors.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text(
              "Couldn't reach AI",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            PressableScale(
              passthrough: true,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Symbols.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String text;
  final ValueChanged<String> onPrompt;

  static const _fallbacks = <String>[
    'My best pictures',
    'Sunsets',
    'Photos of friends',
  ];

  const new({super.key, required this.text, required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final m3e = context.m3e;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Symbols.search_off, size: 32, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              'No matches',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              text.isEmpty ? 'Try a different phrasing, or pick a suggestion below.' : text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _fallbacks.map((p) {
                return PressableScale(
                  onTap: () => onPrompt(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(m3e.shapeExtraLarge - 8),
                    ),
                    child: Text(
                      p,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
                  Icon(Symbols.history, size: 16, color: colors.onSurfaceVariant),
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

class _SaveQueryBar extends StatelessWidget {
  final String query;

  const _SaveQueryBar({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSaved = settings.isSavedSearch(query);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              query,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PressableScale(
            onTap: () => settings.toggleSavedSearch(query),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(isSaved ? Symbols.bookmark : Symbols.bookmark_add, size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    isSaved ? 'Saved' : 'Save',
                    style: theme.textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
