import 'package:aves/widgets/common/motion/spring_transition.dart';
import 'package:material_ui/material_ui.dart';

/// Staggered entrance animation for info page sections.
///
/// Uses the M3E spring physics from `SpringAnimatedValue` instead of a
/// standard tween curve, so the slide-up settles with a natural bounce.
class InfoFadeIn extends StatefulWidget {
  final Widget child;
  final int index;

  const InfoFadeIn({
    super.key,
    required this.child,
    this.index = 0,
  });

  @override
  State<InfoFadeIn> createState() => _InfoFadeInState();
}

class _InfoFadeInState extends State<InfoFadeIn> {
  double _target = 0.0;

  @override
  void initState() {
    super.initState();
    // Wait one frame so the spring animates from 0 to 1 on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: widget.index * 35), () {
          if (mounted) setState(() => _target = 1.0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) return widget.child;

    return SpringAnimatedValue(
      value: _target,
      builder: (context, t) {
        final opacity = t.clamp(0.0, 1.0);
        final offsetY = (1 - t) * 8;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: widget.child,
          ),
        );
      },
    );
  }
}
