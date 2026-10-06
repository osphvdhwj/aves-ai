import 'package:aves/widgets/common/extensions/theme.dart';
import 'package:material_ui/material_ui.dart';

class HighlightTitle extends StatelessWidget {
  final String title;
  final Color? color;
  final double fontSize;
  final bool enabled;
  final bool showHighlight;

  const new({
    super.key,
    required this.title,
    this.color,
    this.fontSize = 15,
    this.enabled = true,
    this.showHighlight = true,
  });

  static const disabledColor = Colors.grey;

  static List<Shadow> shadows(BuildContext context) => [
    Shadow(
      color: Theme.of(context).isDark ? Colors.black : Colors.white,
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // M3E section title — tighter, heavier weight, no outline, no small-caps
    final theme = Theme.of(context);
    final effectiveColor = enabled
        ? (color ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;
    return Align(
      alignment: .centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: effectiveColor,
          ),
          softWrap: false,
          overflow: TextOverflow.fade,
          maxLines: 1,
        ),
      ),
    );
  }
}
