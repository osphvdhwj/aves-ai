import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/ai/prompt_library.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:aves/model/ai/prompt_service.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/search/delegate.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/search/ai_filters_bar.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AiSearchDelegate extends AvesSearchDelegate {
  final String? initialText;

  /// When set, this entry is prepended to the entries payload of every
  /// query. Used by `@like` ("find similar") so the companion has a
  /// reference image even if the entry isn't in the first 200 visible.
  final AvesEntry? contextEntry;

  List<AiPrompt> _rotating = const [];
  List<String> _dynamic = const [];

  AiSearchDelegate({
    required super.searchFieldLabel,
    required super.searchFieldStyle,
    super.canPop,
    this.initialText,
    this.contextEntry,
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
                    _refresh();
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
                    _refresh();
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
          _QuickActions(
            onTap: (text) => _onPrompt(context, text),
            onInsert: (token) => _insertIntoQuery(token),
          ),
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
          return StatusView(
            icon: Symbols.error,
            isError: true,
            title: 'No reply from the assistant.',
            actionLabel: 'Retry',
            onAction: () => _retry(context),
          );
        }
        if (reply.isModelMissing) {
          return StatusView(
            icon: Symbols.model_training,
            isError: true,
            title: 'Model missing',
            subtitle: 'The AVES+ Tools companion needs a model it does not have yet.',
            actionLabel: 'Retry',
            onAction: () => _retry(context),
          );
        }
        if (reply.isUnsupported) {
          return StatusView(
            icon: Symbols.update,
            isError: true,
            title: 'Update required',
            subtitle: 'This companion build does not support AI search. Update AVES+ Tools.',
            actionLabel: 'Retry',
            onAction: () => _retry(context),
          );
        }
        if (reply.error != null) {
          return StatusView(
            icon: Symbols.error,
            isError: true,
            title: 'Search failed',
            subtitle: reply.error!,
            actionLabel: 'Retry',
            onAction: () => _retry(context),
          );
        }
        final source = context.read<CollectionSource>();
        final entries = reply.entryIds
            .map(source.getEntryById)
            .whereType<AvesEntry>()
            .toList();
        if (entries.isEmpty) {
          if (reply.isIndexEmpty) {
            return StatusView(
              icon: Symbols.model_training,
              title: 'Search index is empty',
              subtitle: 'Build it once so the companion can rank your photos by meaning.',
              actionLabel: 'Build index',
              onAction: () => _buildIndexAndRetry(context),
            );
          }
          return _EmptyResults(
            text: reply.text,
            onPrompt: (p) => _onPrompt(context, p),
          );
        }
        return _FilteredResultsView(
          entries: entries,
          query: currentQuery,
        );
      },
    );
  }

  Future<AiChatReply> _runQuery(BuildContext context, String q) async {
    final source = context.read<CollectionSource>();
    final sample = source.visibleEntries.take(200).toList();

    // If a context entry is provided (e.g. @like), prepend it so it's
    // always in the payload even if it isn't in the visible sample.
    final entries = <AvesEntry>[
      if (contextEntry != null) contextEntry!,
      ...sample.where((e) => e.id != contextEntry?.id),
    ];
    final ids = entries.map((e) => e.id).toList();
    return aiService.chat(
      q,
      entryIds: ids,
      entries: AiService.entriesPayload(entries),
    );
  }

  void _retry(BuildContext context) {
    _lastQuery = null;
    _resultFuture = null;
    showResults(context);
  }

  /// One-tap CLIP index build over the current collection's images, then
  /// re-runs the query that triggered it.
  Future<void> _buildIndexAndRetry(BuildContext context) async {
    final source = context.read<CollectionSource>();
    final entries = source.visibleEntries.where((e) => e.isImage).toList();
    if (entries.isEmpty) {
      _retry(context);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IndexBuildDialog(entries: entries),
    );
    _retry(context);
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

  /// Force the search page to rebuild without touching the query text.
  /// Used after clearing saved searches / history.
  void _refresh() {
    final current = currentBody;
    currentBodyNotifier.value = null;
    currentBodyNotifier.value = current;
  }

  void _insertIntoQuery(String token) {
    final controller = queryTextController;
    final current = controller.text;
    final needsSpace = current.isNotEmpty && !current.endsWith(' ');
    final next = '$current${needsSpace ? ' ' : ''}$token ';
    query = next;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: next.length));
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

  const _HeroCard({
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

  const _PromptGrid({
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

  const _PromptTile({
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
  final ValueChanged<String> onInsert;

  static List<(String, IconData)> get _actions =>
      AiCommands.all.map((c) => (c.token, _iconForCommand(c.token))).toList();

  static const _commandGroup = <String>{'/find', '/dup', '/blur', '/receipt', '/clean', '/translate', '/objects', '/faces'};

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

  const _QuickActions({required this.onTap, required this.onInsert});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m3e = context.m3e;
    final actions = _actions;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: actions.length + 1,
        itemBuilder: (context, index) {
          if (index == actions.length) {
            // Trailing spacer
            return const SizedBox(width: 4);
          }

          final (token, icon) = actions[index];
          final isMode = token.startsWith('@');
          final tint = isMode ? colors.tertiary : colors.primary;

          // Show a divider only at the /→@ boundary.
          final prev = index > 0 ? actions[index - 1].$1 : '';
          final showDivider = isMode && _commandGroup.contains(prev);

          final chip = PressableScale(
            onTap: () => onTap(token),
            onLongPress: () => onInsert(token),
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

          if (!showDivider) {
            return Padding(
              padding: EdgeInsets.only(right: index == actions.length - 1 ? 0 : 8),
              child: chip,
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  child: VerticalDivider(
                    width: 16,
                    thickness: 1,
                    color: colors.outlineVariant,
                  ),
                ),
                const SizedBox(width: 8),
                chip,
              ],
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

  const _FaceRow({super.key, this.people, this.onPick, this.onSeeAll});

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

  const _PersonCircle({
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

  const _ResultsHeader({super.key, required this.count});

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
  final String query;

  const _ResultGrid({super.key, required this.entries, required this.query});

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
    // Personalization signal for the companion's auto-training: the user
    // picked this result for this query.
    aiService.feedback(type: 'find_like', entryId: entry.id, query: query);
    Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: EntryViewerPage.routeName),
        builder: (_) => EntryViewerPage(initialEntry: entry),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// index build progress
// ─────────────────────────────────────────────────────────────
class _IndexBuildDialog extends StatefulWidget {
  final List<AvesEntry> entries;

  const _IndexBuildDialog({super.key, required this.entries});

  @override
  State<_IndexBuildDialog> createState() => _IndexBuildDialogState();
}

class _IndexBuildDialogState extends State<_IndexBuildDialog> {
  int _done = 0;
  bool _cancelled = false;
  bool _running = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await aiService.indexBuild(
        widget.entries,
        onProgress: (done, total) {
          if (mounted) setState(() => _done = done);
        },
        isCancelled: () => _cancelled,
      );
    } catch (e, s) {
      await reportService.recordError(e, s);
      _error = e.toString();
    }
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.entries.length;
    return AlertDialog(
      title: const Text('Building search index'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: total == 0 ? 1 : _done / total),
          const SizedBox(height: 12),
          Text(
            _error != null
                ? 'Index build failed: $_error'
                : _cancelled
                    ? 'Cancelled after $_done of $total photos.'
                    : _running
                        ? 'Embedded $_done of $total photos…'
                        : 'Done — processed $total photos. Search is ready.',
          ),
        ],
      ),
      actions: [
        if (_running)
          TextButton(
            onPressed: _cancelled ? null : () => setState(() => _cancelled = true),
            child: const Text('Cancel'),
          ),
        if (!_running)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// loading / error / empty
// ─────────────────────────────────────────────────────────────
class _LoadingState extends StatefulWidget {
  const _LoadingState({super.key});

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


class _EmptyResults extends StatelessWidget {
  final String text;
  final ValueChanged<String> onPrompt;

  static const _fallbacks = <String>[
    'My best pictures',
    'Sunsets',
    'Photos of friends',
  ];

  const _EmptyResults({super.key, required this.text, required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusView(
              icon: Symbols.search_off,
              title: text.isEmpty ? 'No results' : text,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _fallbacks
                  .map((p) => PressableScale(
                        onTap: () => onPrompt(p),
                        child: Chip(
                          label: Text(p),
                          side: BorderSide(color: colors.outlineVariant),
                          backgroundColor: colors.surface,
                        ),
                      ))
                  .toList(),
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

  const _HistoryChips({
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
                borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge),
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

class _FilteredResultsView extends StatefulWidget {
  final List<AvesEntry> entries;
  final String query;

  const _FilteredResultsView({required this.entries, required this.query});

  @override
  State<_FilteredResultsView> createState() => _FilteredResultsViewState();
}

class _FilteredResultsViewState extends State<_FilteredResultsView> {
  Set<AiFilterKind> _selected = {};
  late List<AvesEntry> _filtered;

  // Matches media-kind words in the query. Deliberately conservative;
  // the local filter is a hint, not a hard rule, so it only preselects
  // a chip when the query says "image(s)" / "photo(s)" / "pic(s)",
  // "video(s)" / "movie(s)" / "clip(s)", or "animated" / "gif(s)".
  static final _imageRe = RegExp(r'\b(?:images?|photos?|pictures?|pics?)\b', caseSensitive: false);
  static final _videoRe = RegExp(r'\b(?:videos?|movies?|clips?)\b', caseSensitive: false);
  static final _animatedRe = RegExp(r'\b(?:animated|gifs?)\b', caseSensitive: false);

  static Set<AiFilterKind> _parseKinds(String query) {
    final out = <AiFilterKind>{};
    if (_imageRe.hasMatch(query)) out.add(AiFilterKind.images);
    if (_videoRe.hasMatch(query)) out.add(AiFilterKind.videos);
    if (_animatedRe.hasMatch(query)) out.add(AiFilterKind.animated);
    return out;
  }

  @override
  void initState() {
    super.initState();
    _selected = _parseKinds(widget.query);
    _filtered = _applyFilter(widget.entries, _selected);
  }

  @override
  void didUpdateWidget(covariant _FilteredResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries, widget.entries) || oldWidget.query != widget.query) {
      _selected = _parseKinds(widget.query);
      _filtered = _applyFilter(widget.entries, _selected);
    }
  }

  static List<AvesEntry> _applyFilter(List<AvesEntry> source, Set<AiFilterKind> sel) {
    if (sel.isEmpty) return source;
    return source.where((e) => sel.any((k) => k.test(e))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _filtered.isEmpty;
    final allEmpty = widget.entries.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsHeader(count: _filtered.length),
        _SaveQueryBar(query: widget.query),
        if (!allEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: AiFiltersBar(
              entries: widget.entries,
              selected: _selected,
              onSelectionChanged: (s) => setState(() {
                _selected = s;
                _filtered = _applyFilter(widget.entries, _selected);
              }),
            ),
          ),
        Expanded(
          child: empty
              ? const StatusView(
                  icon: Symbols.filter_alt_off,
                  title: 'No results match the filters',
                  subtitle: 'Clear one of the chips above to see more.',
                )
              : _ResultGrid(entries: _filtered, query: widget.query),
        ),
      ],
    );
  }
}
