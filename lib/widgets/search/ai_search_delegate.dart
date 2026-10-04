import 'package:aves/model/ai/prompt_library.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/model/ai/prompt_service.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/search/delegate.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Placeholder AI search surface. Behavior to be added incrementally:
///   - dynamic prompts from AVES library data (albums, tags, dates)
///   - "/" command palette (Telegram-style, filters by typed prefix)
///   - "@" modifier palette (deep / fast / ocr / person / like)
///   - command + query history (separate from the old search history)
///   - "me" face onboarding card
///   - inline result grid rendered in the results body
class AiSearchDelegate extends AvesSearchDelegate {
  final String? initialText;

  List<AiPrompt> _rotating = const [];

  new({
    required super.searchFieldLabel,
    required super.searchFieldStyle,
    super.canPop,
    this.initialText,
  }) : super(routeName: SearchPage.routeName) {
    query = initialText ?? '';
    _rotating = PromptLibrary.pick(6);
  }

  List<String> _dynamic = const [];

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);

    // Build dynamic prompts once per delegate lifetime.
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Ask AI', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Ask about your photos. Use / for commands, @ for modes.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _FaceRow(),
          const SizedBox(height: 16),
          _sectionTitle(theme, 'Try asking'),
          const SizedBox(height: 8),
          _PromptCard(
            title: 'My best pictures',
            subtitle: 'A curated view of your top shots',
            isSpecial: true,
            onTap: () => _onPrompt(context, 'My best pictures'),
          ),
          const SizedBox(height: 8),
          ..._dynamic.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PromptCard(
                  title: p,
                  subtitle: 'from your library',
                  onTap: () => _onPrompt(context, p),
                ),
              )),
          ..._rotating.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PromptCard(
                  title: p.text,
                  subtitle: p.category,
                  onTap: () => _onPrompt(context, p.text),
                ),
              )),
          const SizedBox(height: 16),
          _sectionTitle(theme, 'Type directly'),
          const SizedBox(height: 8),
          _hint(theme, '/  commands - find, dup, blur, receipt'),
          _hint(theme, '@  modes - deep, fast, ocr, person, like'),
        ],
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // No query execution yet.
    return const SizedBox();
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
      );

  Widget _hint(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text, style: theme.textTheme.bodySmall),
      );

  void _onPrompt(BuildContext context, String text) {
    query = text;
    showResults(context);
  }
}

class _PromptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSpecial;
  final VoidCallback onTap;

  const new({
    required this.title,
    required this.subtitle,
    this.isSpecial = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isSpecial
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isSpecial
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return PressableScale(
      onTap: onTap,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge?.copyWith(color: fg, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceRow extends StatelessWidget {
  static const _circleDim = 56.0;

  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _circleDim,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == 6) {
            return PressableScale(
              onTap: () => _notify(context, 'more'),
              child: Container(
                width: _circleDim,
                height: _circleDim,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return PressableScale(
            onTap: () => _notify(context, 'person ${i + 1}'),
            child: Container(
              width: _circleDim,
              height: _circleDim,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: theme.colorScheme.onSecondaryContainer),
            ),
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
