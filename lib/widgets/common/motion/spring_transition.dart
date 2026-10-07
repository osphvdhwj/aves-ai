import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Spring-settled implicit animation.
///
/// Behaves like [AnimatedScale] / [AnimatedOpacity], but the settle motion
/// uses the M3E spring descriptor (damping / stiffness / mass) from
/// [M3ETokens] instead of a fixed curve. All M3E expressive motion — press
/// release, page transitions, section reveals — goes through here.
class SpringAnimatedValue extends StatefulWidget {
  final double value;
  final Duration fallbackDuration;
  final Widget Function(BuildContext context, double value) builder;

  const new({
    super.key,
    required this.value,
    this.fallbackDuration = const Duration(milliseconds: 300),
    required this.builder,
  });

  @override
  State<SpringAnimatedValue> createState() => _SpringAnimatedValueState();
}

class _SpringAnimatedValueState extends State<SpringAnimatedValue> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late SpringDescription _spring;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: widget.value);
    _controller.addListener(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = context.m3e;
    _spring = SpringDescription(
      mass: tokens.springMass,
      stiffness: tokens.springStiffness,
      damping: tokens.springDamping,
    );
  }

  @override
  void didUpdateWidget(covariant SpringAnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.animateWith(
        SpringSimulation(
          _spring,
          _controller.value,
          widget.value,
          0,
        ),
      );
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      return widget.builder(context, widget.value);
    }
    return widget.builder(context, _controller.value);
  }
}

/// Scale that springs on change. Drop-in replacement for [AnimatedScale]
/// when M3E spring motion is desired.
class SpringScale extends StatelessWidget {
  final double scale;
  final Widget child;
  final Alignment alignment;

  const new({
    super.key,
    required this.scale,
    required this.child,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return SpringAnimatedValue(
      value: scale,
      builder: (context, v) => Transform.scale(
        scale: v,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

/// Opacity that springs on change.
class SpringOpacity extends StatelessWidget {
  final double opacity;
  final Widget child;

  const new({
    super.key,
    required this.opacity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SpringAnimatedValue(
      value: opacity,
      builder: (context, v) => Opacity(opacity: v.clamp(0.0, 1.0), child: child),
    );
  }
}
