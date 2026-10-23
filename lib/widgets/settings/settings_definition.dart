import 'dart:async';

import 'package:aves/widgets/common/basic/list_tiles/common.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/settings/settings_section_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

abstract class SettingsSection {
  String get key;

  Widget icon(BuildContext context);

  String title(BuildContext context);

  Future<List<SettingsTile>> tiles(BuildContext context);

  /// Builds the row that appears on the main Settings page.
  /// This is now a navigation tile, not an expansion tile.
  Widget build(BuildContext sectionContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: PressableScale(
        onTap: () {
          Navigator.of(sectionContext).push(
            MaterialPageRoute(
              settings: RouteSettings(name: '/settings/$key'),
              builder: (context) => SettingsSectionPage(section: this),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(sectionContext).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListTile(
            leading: icon(sectionContext),
            title: Text(
              title(sectionContext),
              style: Theme.of(sectionContext).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Symbols.chevron_right,
              color: Theme.of(sectionContext).colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ),
    );
  }
}

abstract class SettingsTile {
  List<String> get settingKeys;

  String title(BuildContext context);

  Widget build(BuildContext context);
}
