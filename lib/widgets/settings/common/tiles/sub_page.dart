import 'package:aves/widgets/common/basic/list_tiles/common.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class const SettingsSubPageTile({
  super.key,
  required final TitleBuilder title,
  final WidgetBuilder? subtitle,
  required final String routeName,
  required final WidgetBuilder builder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title(context) ?? '?'),
      subtitle: subtitle?.call(context),
      trailing: Icon(
        Symbols.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        Navigator.maybeOf(context)?.push(
          MaterialPageRoute(
            settings: RouteSettings(name: routeName),
            builder: builder,
          ),
        );
      },
    );
  }
}
