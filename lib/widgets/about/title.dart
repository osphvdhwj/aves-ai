import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/styles.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_ui/material_ui.dart';

class AboutSectionTitle extends StatelessWidget {
  final String text;

  const new({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      alignment: .centerStart,
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: Text(text, style: AStyles.knownTitleText),
    );

    if (settings.useTvLayout) {
      child = PressableScale(
        passthrough: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge * 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: .min,
              children: [
                child,
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}
