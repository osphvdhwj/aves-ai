import 'package:aves/app_mode.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/location.dart';
import 'package:aves/model/filters/covered/location.dart';
import 'package:aves/model/settings/enums/coordinate_format.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/map/geo_map.dart';
import 'package:aves/widgets/common/map/map_action_delegate.dart';
import 'package:aves/widgets/common/providers/map_theme_provider.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/viewer/action/entry_info_action_delegate.dart';
import 'package:aves_model/aves_model.dart';
import 'package:aves/widgets/map/map_page.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:aves_map/aves_map.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class LocationSection extends StatefulWidget {
  final CollectionLens? collection;
  final AvesEntry entry;
  final bool showTitle;
  final ValueNotifier<bool> isScrollingNotifier;
  final AFilterCallback onFilterSelection;
  final EntryInfoActionDelegate actionDelegate;

  const new({
    super.key,
    required this.collection,
    required this.entry,
    required this.showTitle,
    required this.isScrollingNotifier,
    required this.onFilterSelection,
    required this.actionDelegate,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  final AvesMapController _mapController = AvesMapController();

  CollectionLens? get collection => widget.collection;

  AvesEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _registerWidget(widget);
  }

  @override
  void didUpdateWidget(covariant LocationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    _mapController.dispose();
    super.dispose();
  }

  void _registerWidget(LocationSection widget) {
    widget.entry.metadataChangeNotifier.addListener(_onMetadataChanged);
  }

  void _unregisterWidget(LocationSection widget) {
    widget.entry.metadataChangeNotifier.removeListener(_onMetadataChanged);
  }

  @override
  Widget build(BuildContext context) {
    if (entry.trashed) return const SizedBox();
    if (!entry.hasGps) {
      return _buildAddLocationCta(context);
    }

    final canNavigate = context.select<ValueNotifier<AppMode>, bool>((v) => v.value.canNavigate);
    return NotificationListener(
      onNotification: (notification) {
        if (notification is OpenMapAppNotification) {
          _openMapApp();
          return true;
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (widget.showTitle) _buildSectionHeading(context),
          MapTheme(
            interactive: false,
            showCoordinateFilter: false,
            navigationButton: canNavigate ? MapNavigationButton.map : MapNavigationButton.none,
            visualDensity: VisualDensity.compact,
            mapHeight: 200,
            child: GeoMap(
              controller: _mapController,
              entries: [entry],
              availableSize: MediaQuery.sizeOf(context),
              isAnimatingNotifier: widget.isScrollingNotifier,
              onUserZoomChange: (zoom) => settings.infoMapZoom = zoom.roundToDouble(),
              onMarkerTap: collection != null && canNavigate ? (location, entry) => _openMapPage(context) : null,
              openMapPage: collection != null ? _openMapPage : null,
            ),
          ),
          ListenableBuilder(
            listenable: entry.addressChangeNotifier,
            builder: (context, child) {
              final filters = <LocationFilter>[];
              if (entry.hasAddress) {
                final address = entry.addressDetails!;
                final country = address.countryName;
                if (country != null && country.isNotEmpty) filters.add(LocationFilter(LocationLevel.country, '$country${LocationFilter.locationSeparator}${address.countryCode}'));
                final state = address.stateName;
                if (state != null && state.isNotEmpty) filters.add(LocationFilter(LocationLevel.state, '$state${LocationFilter.locationSeparator}${address.stateCode}'));
                final place = address.place;
                if (place != null && place.isNotEmpty) filters.add(LocationFilter(LocationLevel.place, place));
              }

              return Column(
                crossAxisAlignment: .start,
                children: [
                  _AddressInfoGroup(entry: entry),
                  if (filters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AvesFilterChip.outlineWidth / 2) + const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filters
                            .map(
                              (filter) => AvesFilterChip(
                                filter: filter,
                                onTap: widget.onFilterSelection,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        'Location',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAddLocationCta(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: .start,
      children: [
        if (widget.showTitle) _buildSectionHeading(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: PressableScale(
            onTap: () => widget.actionDelegate.onActionSelected(context, entry, collection, EntryAction.editLocation),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
              ),
              child: Row(
                children: [
                  Icon(Symbols.add_location_alt, size: 20, color: colors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add a location',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMapPage(BuildContext context) async {
    final baseCollection = collection;
    if (baseCollection == null) return;

    final mapCollection = baseCollection.copyWith(
      listenToSource: true,
      fixedSelection: baseCollection.sortedEntries.where((entry) => entry.hasGps).toList(),
    );
    await Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: MapPage.routeName),
        builder: (context) => MapPage(
          collection: mapCollection,
          initialEntry: entry,
        ),
      ),
    );
  }

  Future<void> _openMapApp() async {
    final latLng = entry.latLng;
    if (latLng != null) {
      await appService.openMap(latLng).then((success) {
        if (!success) showNoMatchingAppDialog(context);
      });
    }
  }

  void _onMetadataChanged() {
    setState(() {});

    final location = entry.latLng;
    if (location != null) {
      _mapController.notifyMarkerLocationChange();
      _mapController.moveTo(location);
    }
  }
}

class _AddressInfoGroup extends StatefulWidget {
  final AvesEntry entry;

  const new({required this.entry});

  @override
  State<_AddressInfoGroup> createState() => _AddressInfoGroupState();
}

class _AddressInfoGroupState extends State<_AddressInfoGroup> {
  late Future<String?> _addressLineLoader;

  AvesEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _addressLineLoader = availability.canLocatePlaces.then((connected) {
      if (connected) {
        return entry.findAddressLine(geocoderLocale: settings.avesLocale);
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _addressLineLoader,
      builder: (context, snapshot) {
        final fullAddress = !snapshot.hasError && snapshot.connectionState == ConnectionState.done ? snapshot.data : null;
        final address = fullAddress ?? entry.shortAddress;
        final l10n = context.l10n;
        return InfoRowGroup(
          info: {
            l10n.viewerInfoLabelCoordinates: settings.coordinateFormat.format(context, entry.latLng!),
            if (address.isNotEmpty) l10n.viewerInfoLabelAddress: address,
          },
        );
      },
    );
  }
}
