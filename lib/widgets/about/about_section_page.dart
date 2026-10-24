import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:material_ui/material_ui.dart';

/// Generic drill-down page for About entries.
///
/// Wraps the given [child] in a scroll view with a title AppBar.
/// Uses the same full-bleed layout as the Settings drill-down pages.
class AboutSectionPage extends StatelessWidget {
  final String title;
  final Widget child;

  const AboutSectionPage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AvesScaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: child,
        ),
      ),
    );
  }
}
