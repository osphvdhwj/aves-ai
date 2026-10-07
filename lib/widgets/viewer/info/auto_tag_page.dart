import 'package:aves/model/auto_tagger.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/filters/covered/tag.dart';
import 'package:aves/model/nsfw_tags.dart';
import 'package:aves/services/nsfw_service.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Review surface for the auto-tagger.
///
/// Shows proposals for the current entry (or the whole collection),
/// grouped by source. Each proposal can be applied individually, or in
/// bulk via Apply all. Reuses the standard `quickTag` path so metadata
/// persistence and notifier fan-out are inherited from the tag editor.
class AutoTagPage extends StatefulWidget {
  static const routeName = '/viewer/info/auto_tag';

  final CollectionLens? collection;
  final AvesEntry entry;
  final EntryInfoActionDelegate actionDelegate;

  const new({
    super.key,
    this.collection,
    required this.entry,
    required this.actionDelegate,
  });

  @override
  State<AutoTagPage> createState() => _AutoTagPageState();
}

class _AutoTagPageState extends State<AutoTagPage> {
  final Set<String> _applied = {};
  final Set<String> _dismissed = {};
  late Future<List<TagProposal>> _loader;
  bool _collectionMode = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<List<TagProposal>> _load() async {
    await NsfwTags.load();
    final tagger = AutoTagger();
    final proposals = <TagProposal>[];
    final seen = <String>{};

    void collect(Iterable<TagProposal> ps) {
      for (final p in ps) {
        if (seen.add(p.tag.toLowerCase())) proposals.add(p);
      }
    }

    if (_collectionMode) {
      final entries = widget.collection?.sortedEntries ?? [widget.entry];
      for (final e in entries) {
        collect(tagger.proposeNew(e));
      }
    } else {
      collect(tagger.proposeNew(widget.entry));
      // Pixel-level NSFW scoring through the AI companion. Skip entirely
      // when the companion does not advertise `nsfw` — saves an IPC hop.
      final health = await aiService.health();
      if (health.has('nsfw')) {
        final nsfw = await nsfwService.classify(widget.entry);
        final tag = nsfw.tagFor(threshold: 0.75);
        if (tag != null) {
          collect([TagProposal(tag: tag, source: 'nsfw-classifier', confidence: nsfw.score!.clamp(0.0, 1.0))]);
        }
      }
    }

    proposals.sort((a, b) => b.confidence.compareTo(a.confidence));
    return proposals;
  }

  Future<void> _apply(TagProposal p) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      await widget.actionDelegate.quickTag(context, widget.entry, TagFilter(p.tag));
      if (!mounted) return;
      setState(() => _applied.add(p.tag.toLowerCase()));
      messenger.showSnackBar(
        SnackBar(content: Text('Added "${p.tag}"'), duration: const Duration(seconds: 1)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyAll(List<TagProposal> proposals) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      for (final p in proposals) {
        if (_dismissed.contains(p.tag.toLowerCase())) continue;
        await widget.actionDelegate.quickTag(context, widget.entry, TagFilter(p.tag));
        if (!mounted) return;
        _applied.add(p.tag.toLowerCase());
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Applied ${_applied.length} tags'), duration: const Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Auto-tag'),
        actions: [
          FutureBuilder<List<TagProposal>>(
            future: _loader,
            builder: (context, snapshot) {
              final proposals = (snapshot.data ?? const <TagProposal>[]).where((p) => !_dismissed.contains(p.tag.toLowerCase())).toList();
              return TextButton(
                onPressed: proposals.isEmpty || _busy ? null : () => _applyAll(proposals),
                child: const Text('Apply all'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SwitchListTile.adaptive(
              value: _collectionMode,
              onChanged: (v) {
                setState(() {
                  _collectionMode = v;
                  _loader = _load();
                });
              },
              title: const Text('Whole collection'),
              subtitle: Text(_collectionMode ? 'Propose tags for every entry' : 'Propose tags for this entry only'),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<TagProposal>>(
                future: _loader,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final proposals = (snapshot.data ?? const <TagProposal>[]).where((p) => !_dismissed.contains(p.tag.toLowerCase())).toList();
                  if (proposals.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Symbols.check_circle, size: 56, color: colors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Nothing to suggest',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: proposals.length,
                    itemBuilder: (context, i) {
                      final p = proposals[i];
                      final applied = _applied.contains(p.tag.toLowerCase());
                      return _Row(
                        proposal: p,
                        applied: applied,
                        onApply: () => _apply(p),
                        onDismiss: () => setState(() => _dismissed.add(p.tag.toLowerCase())),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final TagProposal proposal;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _Row({required this.proposal, required this.applied, required this.onApply, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: applied ? colors.secondaryContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proposal.tag,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: applied ? colors.onSecondaryContainer : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${proposal.source} · ${(proposal.confidence * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (applied)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Symbols.check, color: colors.onSecondaryContainer, size: 20),
              )
            else ...[
              PressableScale(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Symbols.close, size: 18, color: colors.onSurfaceVariant),
                ),
              ),
              PressableScale(
                onTap: onApply,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Symbols.add, size: 20, color: colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showAutoTagPage(
  BuildContext context, {
  required AvesEntry entry,
  required EntryInfoActionDelegate actionDelegate,
  CollectionLens? collection,
}) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: AutoTagPage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, __) => AutoTagPage(entry: entry, actionDelegate: actionDelegate, collection: collection),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
