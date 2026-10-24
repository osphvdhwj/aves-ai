import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/nsfw_tags.dart';
import 'package:aves/model/filters/covered/tag.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Picker that surfaces entries from the bundled NSFW vocabulary so the
/// user can tag the current entry as NSFW.
///
/// The list is shipped at `assets/nsfw_tags.txt` (one tag per line). Tapping
/// a suggestion applies it via the info action delegate — same path as the
/// existing tag editor, so the entry's metadata update, DB persistence and
/// notifier fan-out all work unchanged.
Future<void> showNsfwTagPicker(
  BuildContext context, {
  required AvesEntry entry,
  required EntryInfoActionDelegate actionDelegate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NsfwTagPicker(entry: entry, actionDelegate: actionDelegate),
  );
}

class _NsfwTagPicker extends StatefulWidget {
  final AvesEntry entry;
  final EntryInfoActionDelegate actionDelegate;

  const new({required this.entry, required this.actionDelegate});

  @override
  State<_NsfwTagPicker> createState() => _NsfwTagPickerState();
}

class _NsfwTagPickerState extends State<_NsfwTagPicker> {
  final _controller = TextEditingController();
  late Future<List<String>> _initialLoader;
  List<String> _visible = const [];

  @override
  void initState() {
    super.initState();
    _initialLoader = NsfwTags.load().then((all) {
      _visible = all;
      return all;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _filter(String q) async {
    final results = await NsfwTags.search(q, limit: 60);
    if (!mounted) return;
    setState(() => _visible = results);
  }

  Future<void> _apply(String tag) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await widget.actionDelegate.quickTag(context, widget.entry, TagFilter(tag));
    if (!mounted) return;
    nav.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Added "$tag"'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Symbols.shield_moon, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add NSFW tag',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Filter vocabulary…',
                    prefixIcon: const Icon(Symbols.search),
                    filled: true,
                    fillColor: colors.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _initialLoader,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done && _visible.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_visible.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No matches in the NSFW vocabulary.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemCount: _visible.length,
                      itemBuilder: (context, i) {
                        final tag = _visible[i];
                        return PressableScale(
                          onTap: () => _apply(tag),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(tag, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
                                ),
                                Icon(Symbols.add, size: 18, color: colors.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
