import 'package:aves/widgets/about/about_nav_tile.dart';
import 'package:aves/widgets/about/about_section_page.dart';
import 'package:aves/widgets/about/app_ref.dart';
import 'package:aves/widgets/about/bug_report.dart';
import 'package:aves/widgets/about/credits.dart';
import 'package:aves/widgets/about/data_usage.dart';
import 'package:aves/widgets/about/licenses.dart';
import 'package:aves/widgets/about/translators.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/theme/colors.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AboutMobilePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.watch<AvesColorsData>();

    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.aboutPageTitle),
      ),
      body: GestureAreaProtectorStack(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              // App identity: logo, name, version chip
              const AppReference(),
              const SizedBox(height: 24),

              // Card 1: this app
              _AboutCard(
                title: 'This app',
                children: [
                  AboutNavTile(
                    icon: Symbols.data_usage,
                    accentColor: colors.thumbnails,
                    title: l10n.aboutDataUsageSectionTitle,
                    subtitle: 'Cache, database and temp files',
                    routeName: '/about/data_usage',
                    builder: (_) => AboutSectionPage(
                      title: l10n.aboutDataUsageSectionTitle,
                      child: const AboutDataUsage(),
                    ),
                  ),
                  AboutNavTile(
                    icon: Symbols.description,
                    accentColor: colors.xmp,
                    title: 'Licenses',
                    subtitle: 'Open source packages and their licenses',
                    routeName: '/about/licenses',
                    builder: (_) => AboutSectionPage(
                      title: 'Licenses',
                      child: const Licenses(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card 2: this project
              _AboutCard(
                title: 'This project',
                children: [
                  AboutNavTile(
                    icon: Symbols.bug_report,
                    accentColor: colors.privacy,
                    title: l10n.aboutBugSectionTitle,
                    subtitle: 'Report a bug or request a feature',
                    routeName: '/about/bug_report',
                    builder: (_) => AboutSectionPage(
                      title: l10n.aboutBugSectionTitle,
                      child: const BugReport(),
                    ),
                  ),
                  AboutNavTile(
                    icon: Symbols.handshake,
                    accentColor: colors.accessibility,
                    title: l10n.aboutCreditsSectionTitle,
                    subtitle: 'Aves is built on the work of many',
                    routeName: '/about/credits',
                    builder: (_) => AboutSectionPage(
                      title: l10n.aboutCreditsSectionTitle,
                      child: const AboutCredits(),
                    ),
                  ),
                  AboutNavTile(
                    icon: Symbols.translate,
                    accentColor: colors.language,
                    title: l10n.aboutTranslatorsSectionTitle,
                    subtitle: 'Community translators',
                    routeName: '/about/translators',
                    builder: (_) => AboutSectionPage(
                      title: l10n.aboutTranslatorsSectionTitle,
                      child: const AboutTranslators(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded card wrapper that matches the grouped card style used
/// elsewhere in the app (Settings, Info page).
class _AboutCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const new({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 4),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
