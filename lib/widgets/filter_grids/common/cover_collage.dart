import 'package:aves/model/entry/entry.dart';
import 'package:aves/widgets/common/thumbnail/image.dart';
import 'package:material_ui/material_ui.dart';

/// Google Photos-style 2x2 album cover collage.
/// Four thumbnails in a soft-cornered mosaic with a thin gap between cells.
class CoverCollage extends StatelessWidget {
  final List<AvesEntry> entries;
  final double extent;
  final double devicePixelRatio;

  static const double _gap = 2.0;
  static const double _cornerRadius = 16.0;

  const new({
    super.key,
    required this.entries,
    required this.extent,
    required this.devicePixelRatio,
  });

  @override
  Widget build(BuildContext context) {
    assert(entries.length >= 4, 'CoverCollage expects at least 4 entries');
    final cell = (extent - _gap) / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_cornerRadius),
      child: SizedBox(
        width: extent,
        height: extent,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _cell(entries[0], cell),
                  const SizedBox(width: _gap),
                  _cell(entries[1], cell),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            Expanded(
              child: Row(
                children: [
                  _cell(entries[2], cell),
                  const SizedBox(width: _gap),
                  _cell(entries[3], cell),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(AvesEntry entry, double cell) => Expanded(
        child: ThumbnailImage(
          entry: entry,
          extent: cell,
          devicePixelRatio: devicePixelRatio,
        ),
      );
}
