import 'package:aves/app_mode.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/basic/insets.dart';
import 'package:aves/widgets/common/search/route.dart';
import 'package:aves/widgets/search/ai_search_delegate.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves/widgets/viewer/info/ai_tools_page.dart';
import 'package:aves/widgets/viewer/info/extract_text_dialog.dart';
import 'package:aves/widgets/viewer/info/metadata/metadata_dir.dart';
import 'package:aves/widgets/viewer/info/metadata/metadata_section.dart';
import 'package:aves/widgets/viewer/info/secure_share_dialog.dart';
import 'package:aves/widgets/viewer/info/text_select_page.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class InfoMetadataTab extends StatelessWidget {
  final AvesEntry entry;
  final ValueNotifier<Map<String, MetadataDirectory>> metadataNotifier;

  const new({
    super.key,
    required this.entry,
    required this.metadataNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        MetadataSectionSliver(
          entry: entry,
          metadataNotifier: metadataNotifier,
        ),
        const BottomPaddingSliver(),
      ],
    );
  }
}

class InfoAiToolsTab extends StatelessWidget {
  final AvesEntry entry;
  final CollectionLens? collection;

  const new({
    super.key,
    required this.entry,
    this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AiToolTile(
          icon: Symbols.auto_awesome,
          title: 'Describe this photo',
          subtitle: 'Let AI describe what\'s in the image',
          onTap: () => showAiToolsPage(context, entry, collection: collection),
        ),
        _AiToolTile(
          icon: Symbols.image_search,
          title: 'Find similar photos',
          subtitle: 'See visually similar images',
          onTap: () {
            Navigator.maybeOf(context)?.push(
              SearchPageRoute(
                delegate: AiSearchDelegate(
                  searchFieldLabel: 'Find similar',
                  searchFieldStyle: Themes.searchFieldStyle(context),
                  initialText: '@like',
                  contextEntry: entry,
                ),
                background: Theme.of(context).scaffoldBackgroundColor,
              ),
            );
          },
        ),
        _AiToolTile(
          icon: Symbols.text_fields,
          title: 'Extract text (OCR)',
          subtitle: 'Find text in this image',
          onTap: () => showExtractTextDialog(context, entry),
        ),
        _AiToolTile(
          icon: Symbols.text_select_start,
          title: 'Select text',
          subtitle: 'Select text manually',
          onTap: () => showTextSelectPage(context, entry),
        ),
        _AiToolTile(
          icon: Symbols.shield_lock,
          title: 'Secure share',
          subtitle: 'Share with privacy',
          onTap: () => showSecureShareDialog(context, entry),
        ),
      ],
    );
  }
}

class _AiToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const new({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Symbols.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class InfoActionsTab extends StatelessWidget {
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
    final appMode = context.watch<ValueNotifier<AppMode>>().value;
    bool isVisible(EntryAction action) => actionDelegate.isVisible(
      appMode: appMode,
      targetEntry: entry,
      action: action,
    );

    final commonActions = EntryActions.commonMetadataActions.where(isVisible);
    final formatSpecificActions = EntryActions.formatSpecificMetadataActions.where(isVisible);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...commonActions.map((action) => ListTile(
          leading: action.getIcon(),
          title: Text(action.getText(context)),
          enabled: actionDelegate.canApply(entry, action),
          onTap: () => actionDelegate.onActionSelected(context, entry, collection, action),
        )),
        if (formatSpecificActions.isNotEmpty) const Divider(),
        ...formatSpecificActions.map((action) => ListTile(
          leading: action.getIcon(),
          title: Text(action.getText(context)),
          enabled: actionDelegate.canApply(entry, action),
          onTap: () => actionDelegate.onActionSelected(context, entry, collection, action),
        )),
      ],
    );
  }
}
