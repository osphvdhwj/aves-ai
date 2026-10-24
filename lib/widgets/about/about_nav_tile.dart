import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// A tappable navigation row for the About page.
///
/// Mirrors the card style used on Settings and Info: rounded leading
/// icon square, title + optional subtitle, trailing chevron.
class AboutNavTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final WidgetBuilder builder;
  final String routeName;

  const new({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    required this.builder,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PressableScale(
      passthrough: true,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(context.m3e.shapeMedium),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              )
            : null,
        trailing: Icon(
          Symbols.chevron_right,
          color: colors.onSurfaceVariant,
        ),
        onTap: () {
          Navigator.maybeOf(context)?.push(
            MaterialPageRoute(
              settings: RouteSettings(name: routeName),
              builder: builder,
            ),
          );
        },
      ),
    );
  }
}
