import 'package:aves/theme/durations.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/utils/debouncer.dart';
import 'package:aves/widgets/common/basic/font_size_icon_theme.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/theme/m3e_tokens.dart';

import 'package:material_ui/material_ui.dart';

class QueryBar extends StatefulWidget {
  final ValueNotifier<String> queryNotifier;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? leadingPadding;
  final IconData? icon;
  final String? hintText;
  final bool editable;

  const new({
    super.key,
    required this.queryNotifier,
    this.focusNode,
    this.leadingPadding,
    this.icon,
    this.hintText,
    this.editable = true,
  });

  @override
  State<QueryBar> createState() => _QueryBarState();

  // M3E pill input — slightly taller than legacy toolbar
  static double getPreferredHeight(TextScaler textScaler) => textScaler.scale(64);
}

class _QueryBarState extends State<QueryBar> {
  final Debouncer _debouncer = Debouncer(delay: ADurations.searchDebounceDelay);
  late TextEditingController _controller;

  ValueNotifier<String> get queryNotifier => widget.queryNotifier;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: queryNotifier.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clearButton = IconButton(
      icon: const Icon(AIcons.clear),
      onPressed: widget.editable
          ? () {
              _controller.clear();
              queryNotifier.value = '';
            }
          : null,
      tooltip: context.l10n.clearTooltip,
    );

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!,
      child: FontSizeIconTheme(
        child: Row(
          crossAxisAlignment: .center,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  decoration: InputDecoration(
                    icon: Padding(
                      padding: widget.leadingPadding ?? const EdgeInsetsDirectional.only(start: 16),
                      // set theme at this level because `InputDecoration` defines its own `IconTheme` with a fixed size
                      child: FontSizeIconTheme(
                        child: Icon(
                          widget.icon ?? AIcons.titleFilter,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    hintText: widget.hintText ?? MaterialLocalizations.of(context).searchFieldLabel,
                    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (s) => _debouncer(() => queryNotifier.value = s.trim()),
                  enabled: widget.editable,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 16),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) => AnimatedSwitcher(
                  duration: ADurations.appBarActionChangeAnimation,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      axis: Axis.horizontal,
                      sizeFactor: animation,
                      child: child,
                    ),
                  ),
                  child: value.text.isNotEmpty ? clearButton : const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
