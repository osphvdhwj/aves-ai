import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

class ScrollLabel extends StatelessWidget {
  final Animation<double> animation;
  final Color backgroundColor;
  final Widget child;

  const ScrollLabel({
    super.key,
    required this.child,
    required this.animation,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 12.0),
        child: Material(
          elevation: 4.0,
          color: backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(context.m3e.shapeLarge)),
          child: child,
        ),
      ),
    );
  }
}
