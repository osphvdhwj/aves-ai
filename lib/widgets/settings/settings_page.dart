
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/settings/accessibility/accessibility.dart';
import 'package:aves/widgets/settings/ai/ai.dart';
import 'package:aves/widgets/settings/display/display.dart';
import 'package:aves/widgets/settings/language/language.dart';
import 'package:aves/widgets/settings/navigation/navigation.dart';
import 'package:aves/widgets/settings/privacy/privacy.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:aves/widgets/settings/settings_mobile_page.dart';
import 'package:aves/widgets/settings/settings_tv_page.dart';
import 'package:aves/widgets/settings/thumbnails/thumbnails.dart';
import 'package:aves/widgets/settings/video/video.dart';
import 'package:aves/widgets/settings/viewer/viewer.dart';
import 'package:material_ui/material_ui.dart';

class SettingsPage extends StatelessWidget {
  static const routeName = '/settings';

  static final List<SettingsSection> sections = [
    NavigationSection(),
    ThumbnailsSection(),
    ViewerSection(),
    VideoSection(),
    PrivacySection(),
    AccessibilitySection(),
    AiSection(),
    DisplaySection(),
    LanguageSection(),
  ];

  const new({super.key});

  @override
  Widget build(BuildContext context) {
    if (settings.useTvLayout) {
      return const SettingsTvPage();
    } else {
      return const SettingsMobilePage();
    }
  }
}

class SettingsListView extends StatelessWidget {
  final List<Widget> children;

  const new({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          // dense style font for tile subtitles, without modifying title font
          bodyMedium: const TextStyle(fontSize: 12),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          _SettingsHeader(),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize how Aves + looks and behaves.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
