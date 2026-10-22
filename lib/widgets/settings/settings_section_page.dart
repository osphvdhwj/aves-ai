import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:material_ui/material_ui.dart';

class SettingsSectionPage extends StatelessWidget {
  final SettingsSection section;

  const new({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
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

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                return tiles[index].build(context);
              },
            );
          },
        ),
      ),
    );
  }
}
