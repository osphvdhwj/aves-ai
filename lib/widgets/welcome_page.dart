import 'package:aves/widgets/home/home_page.dart';
import 'package:material_ui/material_ui.dart';

/// Deprecated. Aves + skips the welcome/terms gate entirely.
/// Kept as a stub so stale imports still resolve; not reachable from the app.
@Deprecated('Aves + skips the welcome page; use HomePage directly.')
class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}
