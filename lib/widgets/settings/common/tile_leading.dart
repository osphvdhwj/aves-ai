import 'package:aves/theme/durations.dart';
import 'package:aves/theme/styles.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/extensions/theme.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

class const SettingsTileLeading({
  super.key,
  required final IconData icon,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // M3E 2026 — 12dp rounded square with a soft tonal background.
    return AnimatedContainer(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
      ),
      duration: ADurations.themeColorModeAnimation,
      child: Icon(
        icon,
        size: 22,
        color: color,
      ),
    );
  }
}
