import 'dart:async';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/viewer/info/info_date_header.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import 'package:material_ui/material_ui.dart';

/// Google Photos-style top section for the info page.
///
/// M3E-styled header:
///   - large emphasized date header
///   - editable caption line ("Add a caption" when empty)
///   - People row (placeholder until face clustering ships)
///   - Album row with thumbnail, name, and item count
class InfoHeaderSection extends StatelessWidget {
  final AvesEntry entry;
  final CollectionLens? collection;
  final EntryInfoActionDelegate actionDelegate;

  const new({
    super.key,
    required this.entry,
    this.collection,
    required this.actionDelegate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context, theme),
          const SizedBox(height: 12),
          _buildCaption(context, theme),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, ThemeData theme) {
    return InfoDateHeader(entry: entry);
  }

  Widget _buildCaption(BuildContext context, ThemeData theme) {
    return _CaptionRow(
      entry: entry,
      collection: collection,
      actionDelegate: actionDelegate,
    );
  }

}

/// Caption surface: reads the XMP title from catalog metadata (sync) and the
/// description via overlay metadata (async, live from the file). Reloads when
/// the entry's metadata change notifier fires or when the entry changes.
class _CaptionRow extends StatefulWidget {
  final AvesEntry entry;
  final CollectionLens? collection;
  final EntryInfoActionDelegate actionDelegate;

  const new({
    required this.entry,
    this.collection,
    required this.actionDelegate,
  });

  @override
  State<_CaptionRow> createState() => _CaptionRowState();
}

class _CaptionRowState extends State<_CaptionRow> {
  String? _description;

  AvesEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    entry.metadataChangeNotifier.addListener(_onMetadataChanged);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _CaptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      oldWidget.entry.metadataChangeNotifier.removeListener(_onMetadataChanged);
      entry.metadataChangeNotifier.addListener(_onMetadataChanged);
      _description = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    entry.metadataChangeNotifier.removeListener(_onMetadataChanged);
    super.dispose();
  }

  void _onMetadataChanged() {
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final fields = await metadataFetchService.getOverlayMetadata(entry, {MetadataSyntheticField.description});
      if (!mounted) return;
      setState(() => _description = fields.description);
    } catch (_) {
      if (!mounted) return;
      setState(() => _description = null);
    }
  }

  Future<void> _showCaptionMenu(BuildContext context, String title, String description) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              ListTile(
                leading: const Icon(Symbols.content_copy),
                title: const Text('Copy title'),
                onTap: () => Navigator.of(context).pop('copy-title'),
              ),
            if (description.isNotEmpty)
              ListTile(
                leading: const Icon(Symbols.content_copy),
                title: const Text('Copy description'),
                onTap: () => Navigator.of(context).pop('copy-desc'),
              ),
            ListTile(
              leading: const Icon(Symbols.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'copy-title':
        await Clipboard.setData(ClipboardData(text: title));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title copied'), duration: Duration(seconds: 1)));
      case 'copy-desc':
        await Clipboard.setData(ClipboardData(text: description));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description copied'), duration: Duration(seconds: 1)));
      case 'edit':
        if (!mounted) return;
        widget.actionDelegate.onActionSelected(context, entry, widget.collection, EntryAction.editTitleDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.m3e;
    final colors = theme.colorScheme;
    final title = (entry.catalogMetadata?.xmpTitle ?? '').trim();
    final description = (_description ?? '').trim();
    final hasCaption = title.isNotEmpty || description.isNotEmpty;

    return PressableScale(
      onTap: () => widget.actionDelegate.onActionSelected(context, entry, widget.collection, EntryAction.editTitleDescription),
      onLongPress: hasCaption ? () => _showCaptionMenu(context, title, description) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(tokens.shapeMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                hasCaption ? Symbols.notes : Symbols.add,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasCaption
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (title.isNotEmpty && description.isNotEmpty) const SizedBox(height: 2),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Text(
                      'Add a caption...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
