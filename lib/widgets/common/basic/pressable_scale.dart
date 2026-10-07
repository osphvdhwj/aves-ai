import 'package:aves/widgets/common/motion/spring_transition.dart';
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
  /// When true, this widget does not consume taps; it only tracks press state
  /// for scale feedback. Use to wrap widgets that already handle taps, e.g.
  /// a `ListTile` with its own `onTap`.
  final bool passthrough;

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
    this.passthrough = false,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && (widget.passthrough || widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool v) {
    if (!_interactive) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      behavior: widget.passthrough ? HitTestBehavior.translucent : widget.behavior,
      onTap: (widget.passthrough || !_interactive) ? null : widget.onTap,
      onLongPress: (widget.passthrough || !_interactive) ? null : widget.onLongPress,
      onTapDown: _interactive ? (_) => _setPressed(true) : null,
      onTapUp: _interactive
          ? (_) {
              _setPressed(false);
              widget.onTapUp?.call();
            }
          : null,
      onTapCancel: _interactive ? () => _setPressed(false) : null,
      child: SpringScale(
        scale: (disableAnimations || !_pressed) ? 1.0 : widget.scale,
        child: widget.child,
      ),
    );
  }
}
