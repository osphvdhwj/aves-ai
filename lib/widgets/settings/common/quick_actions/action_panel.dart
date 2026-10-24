import 'package:aves/theme/durations.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

class const ActionPanel({
  super.key,
  final bool highlight = false,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight ? theme.colorScheme.primary : Color.alphaBlend(theme.colorScheme.surfaceTint.withValues(alpha: .2), Themes.secondLayerColor(context));
    return AnimatedContainer(
      foregroundDecoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        border: Border.fromBorderSide(
          BorderSide(
            color: color,
            width: highlight ? 2 : 1,
          ),
        ),
        borderRadius: BorderRadius.all(Radius.circular(context.m3e.shapeSmall)),
      ),
      margin: const EdgeInsets.all(16),
      duration: ADurations.quickActionHighlightAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(context.m3e.shapeSmall)),
        child: child,
      ),
    );
  }
}
