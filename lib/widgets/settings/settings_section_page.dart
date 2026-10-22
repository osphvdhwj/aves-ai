import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:material_ui/material_ui.dart';

class SettingsSectionPage extends StatelessWidget {
  final SettingsSection section;

  const new({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AvesScaffold(
      appBar: AppBar(title: Text(section.title(context))),
      body: SafeArea(
        child: FutureBuilder<List<SettingsTile>>(
          future: section.tiles(context),
          builder: (context, snapshot) {
            final tiles = snapshot.data;
            if (tiles == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (tiles.isEmpty) {
              return const SizedBox();
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < tiles.length; i++) ...[
                        tiles[i].build(context),
                        if (i < tiles.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colors.outlineVariant.withValues(alpha: 0.3),
                          ),
                      ]
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
