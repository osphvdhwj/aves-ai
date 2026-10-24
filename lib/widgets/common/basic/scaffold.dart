import 'package:material_ui/material_ui.dart';

class AvesScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;

  const AvesScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    // prevent conflict between drawer drag gesture and Android navigation gestures
    final drawerEnableOpenDragGesture = MediaQuery.systemGestureInsetsOf(context).horizontal == 0;

    return BackdropGroup(
      child: _AnimatedScaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      ),
    );
  }
}

class _AnimatedScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool drawerEnableOpenDragGesture;

  const _AnimatedScaffold({
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    required this.drawerEnableOpenDragGesture,
  });

  @override
  State<_AnimatedScaffold> createState() => _AnimatedScaffoldState();
}

class _AnimatedScaffoldState extends State<_AnimatedScaffold> {
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final m3e = Theme.of(context).extension<dynamic>(); // Just to keep context
    return Scaffold(
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      drawer: widget.drawer,
      bottomNavigationBar: widget.bottomNavigationBar,
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      extendBody: widget.extendBody,
      drawerEnableOpenDragGesture: widget.drawerEnableOpenDragGesture,
      drawerScrimColor: Colors.black.withValues(alpha: 0.2),
      onDrawerChanged: (isOpened) => setState(() => _isDrawerOpen = isOpened),
      body: AnimatedScale(
        scale: _isDrawerOpen ? 0.92 : 1.0,
        alignment: Alignment.centerRight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _isDrawerOpen ? const Offset(0.04, 0) : Offset.zero,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isDrawerOpen ? 24 : 0),
            child: widget.body,
          ),
        ),
      ),
    );
  }
}
