import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/search/delegate.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder AI search surface. Behavior to be added incrementally:
///   - example prompts on empty state
///   - dynamic prompt generation from AVES library data
///   - "/" command palette (Telegram-style, filters by typed prefix)
///   - "@" modifier palette (deep / fast / ocr / person / like)
///   - command + query history (separate from the old search history)
///   - "me" face onboarding card
///   - inline result grid rendered in the results body
class AiSearchDelegate extends AvesSearchDelegate {
  final String? initialText;

  new({
    required super.searchFieldLabel,
    required super.searchFieldStyle,
    super.canPop,
    this.initialText,
  }) : super(routeName: SearchPage.routeName) {
    query = initialText ?? '';
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ask AI', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Type a question or use / for commands and @ for modes.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Coming soon', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const _Bullet(text: 'Example prompts generated from your library'),
          const _Bullet(text: 'Dynamic "me" face onboarding'),
          const _Bullet(text: '/ commands and @ modes, Telegram-style'),
          const _Bullet(text: 'Query history with tap-to-rerun'),
          const _Bullet(text: 'Inline result grid'),
          const SizedBox(height: 24),
          Text(
            'The original search page is still active when this setting is off.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // No real query yet. Keeps the surface consistent while features are added.
    return const SizedBox();
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const new({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
