import 'package:aves/model/device.dart';
import 'package:aves/ref/locales.dart';
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
    return Center(
      child: Column(
        children: [
          _buildAvesLine(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAvesLine(BuildContext context) {
    final localeName = context.localeName;
    final textScaler = MediaQuery.textScalerOf(context);
    return Row(
      mainAxisSize: .min,
      children: [
        AvesLogo(
          size: textScaler.scale(_getAppTitleStyle(localeName).fontSize!) * 1.3,
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.appName,
          style: _getAppTitleStyle(localeName),
        ),
        const SizedBox(width: 8),
        Text(
          device.packageVersion,
          style: _getAppTitleStyle(localeName),
        ),
      ],
    );
  }

  TextStyle _getAppTitleStyle(String localeName) => TextStyle(
    fontSize: 20,
    fontWeight: .normal,
    letterSpacing: canHaveLetterSpacing(localeName) ? 1 : 0,
    fontFeatures: const [FontFeature.enable('smcp')],
  );
}
