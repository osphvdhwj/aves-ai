import 'package:aves/theme/durations.dart';
import 'package:aves/theme/styles.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/extensions/theme.dart';
import 'package:aves/widgets/common/identity/aves_filter_chip.dart';
import 'package:material_ui/material_ui.dart';

class const SettingsTileLeading({
  super.key,
  required final IconData icon,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // M3E — solid filled circle, no outline. Icon in onColor for contrast.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onColor = isDark ? Colors.black : Colors.white;
    return AnimatedContainer(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      duration: ADurations.themeColorModeAnimation,
      child: Icon(
        icon,
        size: 22,
        color: onColor,
      ),
    );
  }
}
