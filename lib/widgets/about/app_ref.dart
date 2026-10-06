import 'package:aves/model/device.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_logo.dart';
import 'package:material_ui/material_ui.dart';

class AppReference extends StatelessWidget {
  // Aves + uses this fork's own repository for any external references.
  // No upstream deckerst links anywhere.
  static const avesGithub = 'https://github.com/osphvdhwj/aves-ai';
  static const avesFaq = '';

  /// About page shows only app name, version, data usage, and licenses.
  /// No external link chips on any layout.
  static List<Widget> buildLinks(BuildContext context) => const [];

  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Center(
        child: Column(
          children: [
            const AvesLogo(size: 96),
            const SizedBox(height: 16),
            Text(
              context.l10n.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                device.packageVersion,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
