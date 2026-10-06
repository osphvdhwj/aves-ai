import 'package:aves/app_mode.dart';
import 'package:aves/image_providers/app_icon_image_provider.dart';
import 'package:aves/locale/aves_locale.dart';
import 'package:aves/model/app_inventory.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Google Photos-style Details section.
///
/// Filename, date, resolution, size, URI, path, and owner app rows.
/// Extracted from the legacy `BasicSection` so the info page can place it
/// independently of the chips / edit actions row.
class DetailsSection extends StatefulWidget {
  final AvesEntry entry;

  const new({
    super.key,
    required this.entry,
  });

  @override
  State<DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<DetailsSection> {
  Future<String?> _ownerPackageLoader = SynchronousFuture(null);
  Future<void> _appNameLoader = SynchronousFuture(null);

  AvesEntry get entry => widget.entry;

  static const ownerPackageNamePropKey = 'owner_package_name';
  static const iconSize = 20.0;

  @override
  void initState() {
    super.initState();
    if (!entry.trashed && entry.isMediaStoreMediaContent) {
      _ownerPackageLoader = metadataFetchService.hasContentResolverProp(ownerPackageNamePropKey).then((exists) {
        return exists ? metadataFetchService.getContentResolverProp(entry, ownerPackageNamePropKey) : SynchronousFuture(null);
      });
      final isViewerMode = context.read<ValueNotifier<AppMode>>().value == .view;
      if (isViewerMode && settings.isInstalledAppAccessAllowed) {
        _appNameLoader = appInventory.initAppNames();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final infoUnknown = l10n.viewerInfoUnknown;
    final locale = settings.avesLocale;
    final use24hour = MediaQuery.alwaysUse24HourFormatOf(context);

    final title = entry.bestTitle ?? infoUnknown;
    final date = entry.bestDate;
    final dateText = date != null ? formatDateTime(date, locale, use24hour) : infoUnknown;
    final showResolution = !entry.isSvg && entry.isSized;
    final sizeText = entry.sizeBytes != null ? formatFileSize(locale, entry.sizeBytes!) : infoUnknown;
    final path = entry.path;

    return FutureBuilder<String?>(
      future: _ownerPackageLoader,
      builder: (context, snapshot) {
        final ownerPackage = snapshot.data;
        return FutureBuilder<void>(
          future: _appNameLoader,
          builder: (context, snapshot) {
            return InfoRowGroup(
              info: {
                l10n.viewerInfoLabelTitle: title,
                l10n.viewerInfoLabelDate: dateText,
                if (entry.isVideo) ..._buildVideoRows(context),
                if (showResolution) l10n.viewerInfoLabelResolution: context.applyDirectionality(getRasterResolutionText(locale)),
                l10n.viewerInfoLabelSize: context.applyDirectionality(sizeText),
                if (!entry.trashed) l10n.viewerInfoLabelUri: entry.uri,
                l10n.viewerInfoLabelPath: ?path,
                l10n.viewerInfoLabelOwner: ?ownerPackage,
              },
              spanBuilders: {
                l10n.viewerInfoLabelOwner: _ownerHandler(ownerPackage),
              },
            );
          },
        );
      },
    );
  }

  Map<String, String> _buildVideoRows(BuildContext context) {
    return {
      context.l10n.viewerInfoLabelDuration: entry.durationText,
    };
  }

  InfoValueSpanBuilder _ownerHandler(String? ownerPackage) {
    if (ownerPackage == null) return (context, key, value) => [];

    final appName = appInventory.getCurrentAppName(ownerPackage) ?? ownerPackage;
    return (context, key, value) => [
      WidgetSpan(
        alignment: .middle,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, end: 4),
          child: ConstrainedBox(
            // use constraints instead of sizing `Image`,
            // so that it can collapse when handling an empty image
            constraints: const BoxConstraints(
              maxWidth: iconSize,
              maxHeight: iconSize,
            ),
            child: Image(
              image: AppIconImage(
                packageName: ownerPackage,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
      TextSpan(
        text: appName,
        style: InfoRowGroup.valueStyle,
      ),
    ];
  }

  String getRasterResolutionText(AvesLocale locale) {
    var s = entry.getResolutionText(locale);

    // guess whether this is a photo, according to file type
    final isPhoto = [MimeTypes.heic, MimeTypes.heif, MimeTypes.jpeg, MimeTypes.tiff].contains(entry.mimeType) || entry.isRaw;
    if (isPhoto) {
      final megaPixels = (entry.width * entry.height / 1000000).round();
      if (megaPixels > 0) {
        s += ' \u2022 ${locale.numberFormat('0').format(megaPixels)} MP';
      }
    }

    return s;
  }
}
