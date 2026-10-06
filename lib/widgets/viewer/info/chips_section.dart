import 'package:aves/app_mode.dart';
import 'package:aves/locale/aves_locale.dart';
import 'package:aves/model/dynamic_albums.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/favourites.dart';
import 'package:aves/model/entry/extensions/multipage.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/favourites.dart';
import 'package:aves/model/filters/covered/stored_album.dart';
import 'package:aves/model/filters/covered/tag.dart';
import 'package:aves/model/filters/date.dart';
import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/filters/rating.dart';
import 'package:aves/model/filters/type.dart';
import 'package:aves/model/filters/weekday.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/widgets/common/action_controls/quick_choosers/rate_button.dart';
import 'package:aves/widgets/common/action_controls/quick_choosers/tag_button.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Chips row + rating/tags edit buttons for the info page.
///
/// Extracted from the legacy `BasicSection` so the info page can move the
/// Details rows and this section independently. Preserves the entry
/// metadata listener and the TV autofocus-on-scroll-end behaviour.
class ChipsSection extends StatefulWidget {
  final AvesEntry entry;
  final CollectionLens? collection;
  final EntryInfoActionDelegate actionDelegate;
  final ValueNotifier<bool> isScrollingNotifier;
  final ValueNotifier<EntryAction?> isEditingMetadataNotifier;
  final AFilterCallback onFilterSelection;

  const new({
    super.key,
    required this.entry,
    this.collection,
    required this.actionDelegate,
    required this.isScrollingNotifier,
    required this.isEditingMetadataNotifier,
    required this.onFilterSelection,
  });

  @override
  State<ChipsSection> createState() => _ChipsSectionState();
}

class _ChipsSectionState extends State<ChipsSection> with AutomaticKeepAliveClientMixin {
  final FocusNode _chipFocusNode = FocusNode();

  CollectionLens? get collection => widget.collection;

  EntryInfoActionDelegate get actionDelegate => widget.actionDelegate;

  @override
  void initState() {
    super.initState();
    _registerWidget(widget);
    _onScrollingChanged();
  }

  @override
  void didUpdateWidget(covariant ChipsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    _chipFocusNode.dispose();
    super.dispose();
  }

  void _registerWidget(ChipsSection widget) {
    widget.entry.metadataChangeNotifier.addListener(_onMetadataChanged);
    widget.isScrollingNotifier.addListener(_onScrollingChanged);
  }

  void _unregisterWidget(ChipsSection widget) {
    widget.entry.metadataChangeNotifier.removeListener(_onMetadataChanged);
    widget.isScrollingNotifier.removeListener(_onScrollingChanged);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        Focus(
          focusNode: _chipFocusNode,
          skipTraversal: true,
          canRequestFocus: false,
          child: _buildChips(context),
        ),
        _buildEditButtons(context),
      ],
    );
  }

  Widget _buildChips(BuildContext context) {
    final locale = settings.avesLocale;
    final calendar = locale.calendar;
    final calOps = calendar.ops;

    final entry = widget.entry;
    final dateTime = entry.bestDate;
    final album = entry.directory;
    final tags = entry.tags.toList()..sort(compareAsciiUpperCaseNatural);

    final filters = {
      MimeFilter(entry.mimeType),
      if (entry.isAnimated) TypeFilter.animated,
      if (entry.isGeotiff) TypeFilter.geotiff,
      if (entry.isHdr) TypeFilter.hdr,
      if (entry.isMotionPhoto) TypeFilter.motionPhoto,
      if (entry.isRaw) TypeFilter.raw,
      if (entry.isImage && entry.is360) TypeFilter.panorama,
      if (entry.isPureVideo && entry.is360) TypeFilter.sphericalVideo,
      if (entry.isPureVideo && !entry.is360) MimeFilter.video,
      if (entry.isSlowMotion) TypeFilter.slowMotion,
      if (dateTime != null) ...[DateFilter(calendar, DateLevel.ymd, calOps.dateOnly(dateTime)), WeekDayFilter(dateTime.weekday)],
      if (album != null) StoredAlbumFilter(album, collection?.source.getStoredAlbumDisplayName(context, album)),
      ...dynamicAlbums.all.where((v) => v.test(entry)).toSet(),
      if (entry.rating != 0) RatingFilter(entry.rating),
      ...tags.map(TagFilter.new),
    };
    return ListenableBuilder(
      listenable: favourites,
      builder: (context, child) {
        final effectiveFilters = [
          ...filters,
          if (entry.isFavourite) FavouriteFilter.instance,
        ]..sort();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AvesFilterChip.outlineWidth / 2) + const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: effectiveFilters
                .map(
                  (filter) => AvesFilterChip(
                    filter: filter,
                    onTap: widget.onFilterSelection,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildEditButtons(BuildContext context) {
    final appMode = context.watch<ValueNotifier<AppMode>>().value;
    final entry = widget.entry;
    final children =
        [
              EntryAction.editRating,
              EntryAction.editTags,
            ]
            .where(
              (v) => actionDelegate.isVisible(
                appMode: appMode,
                targetEntry: entry,
                action: v,
              ),
            )
            .where((v) => actionDelegate.canApply(entry, v))
            .map((v) => _buildEditMetadataButton(context, v))
            .toList();

    return children.isEmpty
        ? const SizedBox()
        : TooltipTheme(
            data: TooltipTheme.of(context).copyWith(
              preferBelow: false,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AvesFilterChip.outlineWidth / 2) + const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children,
              ),
            ),
          );
  }

  Widget _buildEditMetadataButton(BuildContext context, EntryAction action) {
    final entry = widget.entry;
    return ValueListenableBuilder<EntryAction?>(
      valueListenable: widget.isEditingMetadataNotifier,
      builder: (context, editingAction, child) {
        final isEditing = editingAction != null;
        final onPressed = isEditing ? null : () => actionDelegate.onActionSelected(context, entry, collection, action);
        Widget button;
        switch (action) {
          case .editRating:
            button = RateButton(
              blurred: false,
              onChooserValue: (rating) => actionDelegate.quickRate(context, entry, rating),
              onPressed: onPressed,
            );
          case .editTags:
            button = TagButton(
              blurred: false,
              onChooserValue: (filter) => actionDelegate.quickTag(context, entry, filter),
              onPressed: onPressed,
            );
          default:
            button = IconButton(
              icon: action.getIcon(),
              onPressed: onPressed,
              tooltip: action.getText(context),
            );
        }
        return Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(
                    color: isEditing ? Theme.of(context).disabledColor : context.select<AvesColorsData, Color>((v) => v.neutral),
                    width: AvesFilterChip.outlineWidth,
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(AvesFilterChip.defaultRadius)),
              ),
              child: button,
            ),
            Positioned.fill(
              child: Visibility(
                visible: editingAction == action,
                child: const Padding(
                  padding: EdgeInsets.all(1.0),
                  child: CircularProgressIndicator(
                    strokeWidth: AvesFilterChip.outlineWidth,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onMetadataChanged() => setState(() {});

  void _onScrollingChanged() {
    if (!widget.isScrollingNotifier.value) {
      if (settings.useTvLayout) {
        // using `autofocus` while scrolling seems to fail for widget built offscreen
        // so we give focus to this page when the screen is no longer scrolling
        _chipFocusNode.children.firstOrNull?.requestFocus();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}
