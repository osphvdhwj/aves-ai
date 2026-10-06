import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/identity/highlight_title.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AvesExpansionTile extends StatelessWidget {
  final String value;
  final Widget? leading;
  final String title;
  final Color? highlightColor;
  final ValueNotifier<String?>? expandedNotifier;
  final bool initiallyExpanded, showHighlight;
  final List<Widget> children;

  const new({
    super.key,
    String? value,
    this.leading,
    required this.title,
    this.highlightColor,
    this.expandedNotifier,
    this.initiallyExpanded = false,
    this.showHighlight = true,
    required this.children,
  }) : value = value ?? title;

  @override
  Widget build(BuildContext context) {
    final enabled = children.isNotEmpty == true;
    Widget titleChild = HighlightTitle(
      title: title,
      color: highlightColor,
      enabled: enabled,
      showHighlight: showHighlight,
    );
    if (leading != null) {
      titleChild = Row(
        children: [
          leading!,
          const SizedBox(width: 8),
          Expanded(child: titleChild),
        ],
      );
    }

    final animationDuration = context.select<DurationsData, Duration>((v) => v.expansionTileAnimation);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PressableScale(
      passthrough: true,
      scale: 0.99,
      child: ExpansionTileCard(
      // key is expected by test driver
      key: Key('tilecard-$value'),
      value: value,
      expandedNotifier: expandedNotifier,
      title: titleChild,
      expandable: enabled,
      initiallyExpanded: initiallyExpanded,
      finalPadding: const EdgeInsets.symmetric(vertical: 8.0),
      baseColor: colorScheme.surfaceContainerLow,
      expandedColor: colorScheme.surfaceContainerLow,
      expandedTextColor: colorScheme.onSurface,
      duration: animationDuration,
      shadowColor: Colors.transparent,
      elevation: 0,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const SizedBox(height: 4),
          if (enabled) ...children,
          const SizedBox(height: 4),
        ],
      ),
      ),
    );
  }
}
