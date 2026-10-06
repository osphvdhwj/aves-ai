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
        return Symbols.mood;
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

  static const _actions = <(String, IconData)>[
    ('/find', Symbols.search),
    ('/dup', Symbols.copy_all),
    ('/blur', Symbols.blur_on),
    ('/receipt', Symbols.receipt_long),
    ('@deep', Symbols.psychology),
    ('@fast', Symbols.bolt),
    ('@ocr', Symbols.text_fields),
    ('@person', Symbols.person),
    ('@like', Symbols.favorite),
  ];

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
