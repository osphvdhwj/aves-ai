import 'package:aves/model/entry/entry.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class InfoHeroImage extends StatelessWidget {
  final AvesEntry entry;

  const new({super.key, required this.entry});

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
          child: Image(
            image: entry.getThumbnail(extent: 1024),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: colors.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(Symbols.broken_image, size: 32, color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
