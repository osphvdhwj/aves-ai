import 'package:aves/model/settings/settings.dart';
import 'package:aves/ref/locales.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/basic/text/outlined.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/extensions/theme.dart';
import 'package:aves/widgets/common/fx/highlight_decoration.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

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
    final effectiveColor = enabled
        ? (color ?? Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: effectiveColor,
    );
    return Align(
      alignment: .centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          title,
          style: style,
          softWrap: false,
          overflow: TextOverflow.fade,
          maxLines: 1,
        ),
      ),
    );
  }
}
