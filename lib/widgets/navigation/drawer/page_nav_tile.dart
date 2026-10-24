import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/navigation/drawer/tile.dart';
import 'package:aves/widgets/navigation/nav_item.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

typedef TileRouteBuilder = Route Function(BuildContext context, String routeName, bool topLevel);

class PageNavTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final AvesNavItem navItem;
  final bool Function()? isSelected;

  const PageNavTile({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    required this.navItem,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final routeName = navItem.route;
    return SafeArea(
      top: false,
      bottom: false,
      child: PressableScale(
        passthrough: true,
        scale: 0.97,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge)),
            tileColor: context.currentRouteName == routeName && (isSelected?.call() ?? true)
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            // key is expected by test driver
            key: Key('$routeName-tile'),
            leading: leading ?? DrawerPageIcon(route: routeName),
            title: title ?? DrawerPageTitle(route: routeName),
            trailing: trailing != null
                ? Builder(
                    builder: (context) => DefaultTextStyle.merge(
                      style: TextStyle(
                        color: IconTheme.of(context).color!.withValues(alpha: .6),
                      ),
                      child: trailing!,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.maybeOf(context)?.pop();
              navItem.goTo(context);
            },
            selected: context.currentRouteName == routeName && (isSelected?.call() ?? true),
          ),
        ),
      ),
    );
  }
}
