import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Material 3 Expressive press feedback.
///
/// Scales the whole surface down on press — spring-settled release — instead
/// of relying on the legacy ink ripple. Colour and elevation shifts are the
/// caller's responsibility; this widget only owns scale + gesture.
///
/// Reduced-motion accessibility: when `MediaQuery.disableAnimations` is true,
/// the widget still accepts taps but does not scale.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapUp;
  final double scale;
  final Duration? duration;
  final HitTestBehavior behavior;
  final bool enabled;

  const new({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onTapUp,
    this.scale = 0.96,
    this.duration,
    this.behavior = HitTestBehavior.opaque,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool v) {
    if (!_interactive) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.m3e;
    final duration = widget.duration ?? tokens.durationShort3;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      behavior: widget.behavior,
      onTap: _interactive ? widget.onTap : null,
      onLongPress: _interactive ? widget.onLongPress : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTapUp?.call();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: (disableAnimations || !_pressed) ? 1.0 : widget.scale,
        duration: duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
