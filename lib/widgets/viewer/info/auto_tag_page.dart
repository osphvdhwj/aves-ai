import 'dart:async';

import 'package:aves/model/auto_tagger.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/filters/covered/tag.dart';
import 'package:aves/model/nsfw_tags.dart';
import 'package:aves/services/nsfw_service.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
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

  const AutoTagPage({
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
      // Personalization signal: the user confirms the companion's NSFW
      // scoring, so the learned threshold may move below this score.
      if (p.source == 'nsfw-classifier') {
        unawaited(aiService.feedback(
          type: 'nsfw_explicit',
          entryId: widget.entry.id,
          score: p.confidence,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _dismiss(TagProposal p) {
    setState(() => _dismissed.add(p.tag.toLowerCase()));
    // Personalization signal: the user rejects the companion's NSFW
    // suggestion, so the learned threshold may move above this score.
    if (p.source == 'nsfw-classifier') {
      unawaited(aiService.feedback(
        type: 'nsfw_safe',
        entryId: widget.entry.id,
        score: p.confidence,
      ));
    }
  }

  Future<void> _applyAll(List<TagProposal> proposals) async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final dismissed = _dismissed;
      var appliedCount = 0;

      if (_collectionMode) {
        // In collection mode the visible list is a union of tags across
        // every entry. Applying them all to a single entry is wrong, so
        // re-derive per entry and apply only its own matching tags.
        final tagger = AutoTagger();
        final entries = widget.collection?.sortedEntries ?? [widget.entry];
        for (final e in entries) {
          for (final p in tagger.proposeNew(e)) {
            final key = p.tag.toLowerCase();
            if (dismissed.contains(key)) continue;
            await widget.actionDelegate.quickTag(context, e, TagFilter(p.tag));
            if (!mounted) return;
            _applied.add(key);
            appliedCount++;
          }
        }
      } else {
        for (final p in proposals) {
          final key = p.tag.toLowerCase();
          if (dismissed.contains(key)) continue;
          await widget.actionDelegate.quickTag(context, widget.entry, TagFilter(p.tag));
          if (!mounted) return;
          _applied.add(key);
          appliedCount++;
        }
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_collectionMode
              ? 'Applied $appliedCount tags across the collection'
              : 'Applied $appliedCount tags'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AvesScaffold(
      appBar: AppBar(
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
                    return const StatusView(
                      icon: Symbols.check_circle,
                      title: 'Nothing to suggest',
                      subtitle: 'Every tag this entry could carry has already been applied or dismissed.',
                    );
                  }
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (int i = 0; i < proposals.length; i++) ...[
                              _Row(
                                proposal: proposals[i],
                                applied: _applied.contains(proposals[i].tag.toLowerCase()),
                                onApply: () => _apply(proposals[i]),
                                onDismiss: () => _dismiss(proposals[i]),
                              ),
                              if (i < proposals.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: colors.outlineVariant.withValues(alpha: 0.3),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
    return Container(
      color: applied ? colors.secondaryContainer : Colors.transparent,
      child: ListTile(
        title: Text(
          proposal.tag,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: applied ? colors.onSecondaryContainer : colors.onSurface,
          ),
        ),
        subtitle: Text(
          '${proposal.source} · ${(proposal.confidence * 100).round()}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: applied ? colors.onSecondaryContainer : colors.onSurfaceVariant,
          ),
        ),
        trailing: applied
            ? Icon(Symbols.check, color: colors.onSecondaryContainer, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Dismiss',
                    onPressed: onDismiss,
                    icon: const Icon(Symbols.close, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Add tag',
                    onPressed: onApply,
                    icon: Icon(Symbols.add, size: 20, color: colors.primary),
                  ),
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
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: AutoTagPage.routeName),
      builder: (context) => AutoTagPage(entry: entry, actionDelegate: actionDelegate, collection: collection),
    ),
  );
}
