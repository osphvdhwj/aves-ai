import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/viewer/info/tag_suggestions.dart';
import 'package:aves/model/tag_vocabulary.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Row of AI-suggested tags under the Details section.
///
/// Populated once the AI companion returns recognised keywords for an
/// entry. Until then, an empty state is shown that explains why.
class AiTagsSection extends StatefulWidget {
  final AvesEntry entry;

  const new({super.key, required this.entry});

  @override
  State<AiTagsSection> createState() => _AiTagsSectionState();
}

class _AiTagsSectionState extends State<AiTagsSection> {
  late Future<List<String>> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  @override
  void didUpdateWidget(covariant AiTagsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _loader = _load();
    }
  }

  Future<List<String>> _load() async {
    // Local heuristic suggestions from the album path. Companion-derived
    // tags will be merged here once the AI service exposes them. We
    // preload the bundled vocabulary so suggestions stick to tags the
    // user already uses.
    await TagVocabulary.load();
    return TagSuggester.suggestExisting(widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Row(
              children: [
                Icon(Symbols.auto_awesome, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'Suggested tags',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<String>>(
            future: _loader,
            builder: (context, snapshot) {
              final tags = snapshot.data ?? const <String>[];
              if (tags.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
                  ),
                  child: Text(
                    'Suggestions are drawn from the album name. Tap to add once the delegate is wired.',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (t) => PressableScale(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                          ),
                          child: Text(t, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface)),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
