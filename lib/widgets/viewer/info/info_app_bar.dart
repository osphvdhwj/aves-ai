import 'package:aves/app_mode.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/selection.dart';
import 'package:aves/model/settings/enums/accessibility_animations.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/common/app_bar/app_bar_title.dart';
import 'package:aves/widgets/common/app_bar/sliver_app_bar_title.dart';
import 'package:aves/widgets/common/basic/font_size_icon_theme.dart';
import 'package:aves/widgets/common/basic/popup/menu_row.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/search/route.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/widgets/viewer/info/info_search_delegate.dart';
import 'package:aves/widgets/viewer/info/extract_text_dialog.dart';
import 'package:aves/widgets/viewer/info/text_select_page.dart';
import 'package:aves/widgets/viewer/info/secure_share_dialog.dart';
import 'package:aves/widgets/viewer/info/ai_tools_page.dart';
import 'package:aves/widgets/viewer/info/metadata/metadata_dir.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

class InfoAppBar extends StatelessWidget {
  final AvesEntry entry;
  final CollectionLens? collection;
  final EntryInfoActionDelegate actionDelegate;
  final ValueNotifier<Map<String, MetadataDirectory>> metadataNotifier;
  final VoidCallback onBackPressed;

  const new({
    super.key,
    required this.entry,
    required this.collection,
    required this.actionDelegate,
    required this.metadataNotifier,
    required this.onBackPressed,
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
    final useTvLayout = settings.useTvLayout;
    final animations = context.select<Settings, AccessibilityAnimations>((v) => v.accessibilityAnimations);
    return SliverAppBar(
      leading: useTvLayout
          ? null
          : FontSizeIconTheme(
              child: IconButton(
                // key is expected by test driver
                key: const Key('back-button'),
                icon: const Icon(AIcons.goUp),
                onPressed: onBackPressed,
                tooltip: context.l10n.viewerInfoBackToViewerTooltip,
              ),
            ),
      automaticallyImplyLeading: false,
      title: SliverAppBarTitleWrapper(
        child: InteractiveAppBarTitle(
          onTap: () => _goToSearch(context),
          child: Text(context.l10n.viewerInfoPageTitle),
        ),
      ),
      actions: useTvLayout
          ? []
          : [
              FontSizeIconTheme(
                child: IconButton(
                  icon: const Icon(AIcons.search),
                  onPressed: () => _goToSearch(context),
                  tooltip: MaterialLocalizations.of(context).searchFieldLabel,
                ),
              ),
              FontSizeIconTheme(
                child: FutureBuilder<AiHealth>(
                  future: aiService.health(),
                  builder: (context, snap) {
                    final health = snap.data;
                    final ocrSupported = health?.connected == true && health!.has('ocr');
                    return PopupMenuButton<Object>(
                      icon: const Icon(Symbols.more_vert),
                      tooltip: 'More',
                      itemBuilder: (context) => _buildMenuItems(
                        context,
                        ocrSupported: ocrSupported,
                        commonActions: commonActions,
                        formatSpecificActions: formatSpecificActions,
                        isVisible: isVisible,
                      ),
                      onSelected: (value) => _onMenuSelected(
                        context,
                        value,
                        animations: animations,
                      ),
                      popUpAnimationStyle: animations.popUpAnimationStyle,
                    );
                  },
                ),
              ),
            ],
      floating: true,
      // as of Flutter v3.44.4, `SliverAppBar` does not automatically pick up `systemOverlayStyle` from `AppBar` theme
      systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
    );
  }

  List<PopupMenuEntry<Object>> _buildMenuItems(
    BuildContext context, {
    required bool ocrSupported,
    required Iterable<EntryAction> commonActions,
    required Iterable<EntryAction> formatSpecificActions,
    required bool Function(EntryAction) isVisible,
  }) {
    final items = <PopupMenuEntry<Object>>[];

    // Info-page specific actions, now consolidated into the overflow menu.
    if (entry.isImage && ocrSupported) {
      items.add(_customItem('Extract text', Symbols.text_fields, _AppBarAction.extractText));
      items.add(_customItem('Select text', Symbols.text_select_start, _AppBarAction.selectText));
    }
    items.add(_customItem('Secure share', Symbols.shield_lock, _AppBarAction.secureShare));
    items.add(_customItem('AI tools', Symbols.auto_awesome, _AppBarAction.aiTools));

    // Existing per-entry edit actions (only when the entry supports them).
    if (entry.canEdit && (commonActions.isNotEmpty || formatSpecificActions.isNotEmpty)) {
      items.add(const PopupMenuDivider());
      items.addAll(commonActions.map((action) => _toMenuItem(context, action, enabled: actionDelegate.canApply(entry, action))));
      if (formatSpecificActions.isNotEmpty) {
        items.add(const PopupMenuDivider());
        items.addAll(formatSpecificActions.map((action) => _toMenuItem(context, action, enabled: actionDelegate.canApply(entry, action))));
      }
    }

    if (isVisible(EntryAction.debug)) {
      items.add(const PopupMenuDivider());
      items.add(_toMenuItem(context, EntryAction.debug, enabled: true));
    }

    return items;
  }

  PopupMenuItem<Object> _customItem(String label, IconData icon, _AppBarAction value) {
    return PopupMenuItem<Object>(
      value: value,
      child: MenuRow(text: label, icon: Icon(icon)),
    );
  }

  PopupMenuItem<Object> _toMenuItem(BuildContext context, EntryAction action, {required bool enabled}) {
    return PopupMenuItem<Object>(
      value: action,
      enabled: enabled,
      child: MenuRow(text: action.getText(context), icon: action.getIcon()),
    );
  }

  Future<void> _onMenuSelected(
    BuildContext context,
    Object value, {
    required AccessibilityAnimations animations,
  }) async {
    if (value is EntryAction) {
      // wait for the popup menu to hide before proceeding with the action
      await Future.delayed(animations.popUpAnimationDelay * timeDilation);
      await actionDelegate.onActionSelected(context, entry, collection, value);
      return;
    }
    if (value is _AppBarAction) {
      switch (value) {
        case _AppBarAction.extractText:
          showExtractTextDialog(context, entry);
        case _AppBarAction.selectText:
          showTextSelectPage(context, entry);
        case _AppBarAction.secureShare:
          showSecureShareDialog(context, entry);
        case _AppBarAction.aiTools:
          showAiToolsPage(context, entry, collection: collection);
      }
    }
  }

  void _goToSearch(BuildContext context) {
    final isSelecting = context.read<Selection<AvesEntry>?>()?.isSelecting ?? false;
    Navigator.maybeOf(context)?.push(
      SearchPageRoute(
        delegate: InfoSearchDelegate(
          searchFieldLabel: context.l10n.viewerInfoSearchFieldLabel,
          searchFieldStyle: Themes.searchFieldStyle(context),
          entry: entry,
          metadataNotifier: metadataNotifier,
          isSelecting: isSelecting,
        ),
        background: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

enum _AppBarAction {
  extractText,
  selectText,
  secureShare,
  aiTools,
}
