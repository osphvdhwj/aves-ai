import 'dart:ui' as ui;

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/model/entry/extensions/favourites.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/action_controls/togglers/favourite.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class InfoHeroImage extends StatelessWidget {
  final AvesEntry entry;
  final VoidCallback? onShare;

  const new({super.key, required this.entry, this.onShare});

  @override
  Widget build(BuildContext context) {
    final tokens = context.m3e;
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final height = (width * 0.75).clamp(180.0, 420.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.shapeLarge),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: entry.getThumbnail(extent: 1024),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: colors.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(Symbols.broken_image, size: 32, color: colors.onSurfaceVariant),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GlassPill(
                      child: IconTheme.merge(
                        data: const IconThemeData(color: Colors.white),
                        child: FavouriteToggler(
                          entries: {entry},
                          onPressed: () => entry.toggleFavourite(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onShare != null)
                      _GlassPill(
                        child: IconButton(
                          icon: const Icon(Symbols.share),
                          color: Colors.white,
                          tooltip: 'Share',
                          onPressed: onShare,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;

  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge * 4),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: child,
        ),
      ),
    );
  }
}
