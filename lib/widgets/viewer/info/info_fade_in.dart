import 'dart:async';

import 'package:aves/widgets/common/motion/spring_transition.dart';
import 'package:material_ui/material_ui.dart';

/// Staggered entrance animation for info page sections.
///
/// Uses the M3E spring physics from `SpringAnimatedValue`. The stagger
/// delay is driven by a cancelable [Timer] so it doesn't fire after
/// dispose when the user changes entries quickly.
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
  Timer? _staggerTimer;

  @override
  void initState() {
    super.initState();
    // Delay the target change so the spring animates from 0 to 1 on mount.
    _staggerTimer = Timer(Duration(milliseconds: widget.index * 35), () {
      if (mounted) setState(() => _target = 1.0);
    });
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    super.dispose();
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
