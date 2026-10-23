import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AvesDialog extends StatefulWidget {
  static const confirmationRouteName = '/dialog/confirmation';
  static const warningRouteName = '/dialog/warning';

  final String? title;
  final ScrollController? scrollController;
  final List<Widget>? scrollableContent;
  final double horizontalContentPadding;
  final Widget? content;
  final List<Widget> actions;

  static Radius cornerRadiusOf(BuildContext context) =>
      Radius.circular(context.m3e.shapeExtraLarge);
  static const double defaultHorizontalContentPadding = 24;
  static const double controlCaptionPadding = 16;
  static const double borderWidth = 1.0;
  static const EdgeInsets actionsPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 24);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 8);

  const new({
    super.key,
    this.title,
    this.scrollController,
    this.scrollableContent,
    this.horizontalContentPadding = defaultHorizontalContentPadding,
    this.content,
    this.actions = const [],
  }) : assert((scrollableContent != null) ^ (content != null));

  @override
  State<AvesDialog> createState() => _AvesDialogState();

  /// Kept as a stable API for cover selection dialog and others, but
  /// returns a flat decoration — 2026 M3E dialogs don't use borders.
  static Decoration contentDecoration(BuildContext context) => const BoxDecoration();

  static ShapeBorder shape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(context.m3e.shapeExtraLarge)),
    );
  }
}

class _AvesDialogState extends State<AvesDialog> {
  final ScrollController _internalScrollController = ScrollController();

  ScrollController get scrollController => widget.scrollController ?? _internalScrollController;

  @override
  void dispose() {
    _internalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    return AlertDialog(
      title: title != null
          ? Padding(
              // padding to avoid transparent border overlapping
              padding: const EdgeInsets.symmetric(horizontal: AvesDialog.borderWidth),
              child: DialogTitle(title: title),
            )
          : null,
      titlePadding: EdgeInsets.zero,
      // the `scrollable` flag of `AlertDialog` makes it
      // scroll both the title and the content together,
      // and overflow feedback ignores the dialog shape,
      // so we restrict scrolling to the content instead
      content: _buildContent(context),
      contentPadding: widget.scrollableContent != null
          ? EdgeInsets.zero
          : EdgeInsets.only(
              left: widget.horizontalContentPadding,
              top: 8,
              right: widget.horizontalContentPadding,
              bottom: 8,
            ),
      actions: widget.actions.map((a) => PressableScale(
        passthrough: true,
        scale: 0.94,
        child: a,
      )).toList(),
      actionsPadding: AvesDialog.actionsPadding,
      buttonPadding: AvesDialog.buttonPadding,
      // clipping to prevent highlighted material to bleed through rounded corners
      clipBehavior: Clip.antiAlias,
      shape: AvesDialog.shape(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final content = widget.content;
    if (content != null) {
      return content;
    }

    final scrollableContent = widget.scrollableContent;
    if (scrollableContent != null) {
      Widget child = ListView(
        controller: scrollController,
        shrinkWrap: true,
        children: scrollableContent,
      );

      if (!settings.useTvLayout) {
        child = Theme(
          data: Theme.of(context).copyWith(
            scrollbarTheme: ScrollbarThemeData(
              thumbVisibility: WidgetStateProperty.all(true),
              radius: Radius.circular(context.m3e.shapeLarge),
              crossAxisMargin: 4,
              // adapt margin when corner is around content itself, not outside for the title
              mainAxisMargin: 4 + (widget.title != null ? 0 : context.m3e.shapeExtraLarge / 2),
              interactive: true,
            ),
          ),
          child: Scrollbar(
            controller: scrollController,
            notificationPredicate: (notification) {
              // as of Flutter v3.0.1, the `Scrollbar` does not only respond to the nearest `ScrollView`
              // despite the `defaultScrollNotificationPredicate` checking notification depth,
              // as the notifications coming from the controller in `ListWheelScrollView` in `WheelSelector` still have a depth of 0.
              // Cancelling notification bubbling seems ineffective, so we check the metrics type as a workaround.
              return defaultScrollNotificationPredicate(notification) && notification.metrics is! FixedExtentMetrics;
            },
            child: child,
          ),
        );
      }

      return Container(
        // padding to avoid transparent border overlapping
        padding: const EdgeInsets.symmetric(horizontal: AvesDialog.borderWidth),
        // workaround because the dialog tries
        // to size itself to the content intrinsic size,
        // but the `ListView` viewport does not have one
        width: MediaQuery.sizeOf(context).width / 2,
        child: DecoratedBox(
          decoration: AvesDialog.contentDecoration(context),
          child: child,
        ),
      );
    }

    return const SizedBox();
  }
}

class DialogTitle extends StatelessWidget {
  final String title;

  const new({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

Future<void> showNoMatchingAppDialog(BuildContext context) => showWarningDialog(
  context: context,
  message: context.l10n.noMatchingAppDialogMessage,
);

Future<void> showWarningDialog({
  required BuildContext context,
  required String message,
}) => showAvesDialog<void>(
  context: context,
  builder: (context) => AvesMessageDialog.info(message),
  routeSettings: const RouteSettings(name: AvesDialog.warningRouteName),
);

Future<T?> showAvesDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool fullscreenDialog = false,
  bool? requestFocus,
}) {
  final animate = context.read<Settings>().animate;
  final animationStyle = animate ? null : AnimationStyle.noAnimation;

  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    fullscreenDialog: fullscreenDialog,
    requestFocus: requestFocus,
    animationStyle: animationStyle,
  );
}

class CancelButton<T> extends StatelessWidget {
  final String? text;
  final T? result;

  const new({
    super.key,
    this.text,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.maybeOf(context)?.pop<T>(result),
      // MD2 button labels were upper case but they are lower case in MD3
      child: Text(text ?? Themes.asButtonLabel(context.l10n.cancelTooltip)),
    );
  }
}

class OkButton<T> extends StatelessWidget {
  final String? text;
  final T? result;

  const new({
    super.key,
    this.text,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.maybeOf(context)?.pop<T>(result),
      // MD2 button labels were upper case but they are lower case in MD3
      child: Text(text ?? Themes.asButtonLabel(MaterialLocalizations.of(context).okButtonLabel)),
    );
  }
}

class AvesMessageDialog extends StatelessWidget {
  final String message;
  final List<Widget> actions;

  const new({
    super.key,
    required this.message,
    required this.actions,
  });

  factory info(String message) {
    return AvesMessageDialog(
      message: message,
      actions: const [OkButton()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AvesDialog(
      content: Text(message),
      actions: actions,
    );
  }
}
