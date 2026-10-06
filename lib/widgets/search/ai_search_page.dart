import 'dart:ui';

import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/behaviour/pop/double_back.dart';
import 'package:aves/widgets/common/behaviour/pop/scope.dart';
import 'package:aves/widgets/common/behaviour/pop/tv_navigation.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/search/ai_search_delegate.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiSearchPage extends StatefulWidget {
  static const routeName = '/ai_search';

  final AiSearchDelegate delegate;
  final Animation<double> animation;

  const new({
    super.key,
    required this.delegate,
    required this.animation,
  });

  @override
  State<AiSearchPage> createState() => _AiSearchPageState();
}

class _AiSearchPageState extends State<AiSearchPage> {
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.delegate.searchFieldFocusNode = _inputFocus;
    widget.delegate.queryTextController.addListener(_onQueryChanged);
    widget.delegate.currentBodyNotifier.addListener(_onBodyChanged);
  }

  @override
  void dispose() {
    widget.delegate.queryTextController.removeListener(_onQueryChanged);
    widget.delegate.currentBodyNotifier.removeListener(_onBodyChanged);
    widget.delegate.searchFieldFocusNode = null;
    _inputFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onBodyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _insertCommand(AiCommand cmd) {
    final controller = widget.delegate.queryTextController;
    final text = controller.text;
    final detected = detectPalette(text);
    if (detected == null) {
      controller.text = '$text${cmd.token} ';
    } else {
      final (trigger, filter) = detected;
      final replaceLen = trigger.length + filter.length;
      final head = text.substring(0, text.length - replaceLen);
      controller.text = '$head${cmd.token} ';
    }
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    _inputFocus.requestFocus();
  }

  void _insertTrigger(String trigger) {
    final controller = widget.delegate.queryTextController;
    final text = controller.text;
    final needsSpace = text.isNotEmpty && !text.endsWith(' ');
    controller.text = '$text${needsSpace ? ' ' : ''}$trigger';
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    _inputFocus.requestFocus();
  }

  void _onSubmit() {
    final text = widget.delegate.queryTextController.text.trim();
    if (text.isEmpty) return;
    final detected = detectPalette(text);
    if (detected != null) {
      final matches = AiCommands.match(detected.$1, detected.$2);
      if (matches.isNotEmpty) {
        _insertCommand(matches.first);
        return;
      }
    }
    settings.addAiSearchHistory(text);
    widget.delegate.showResults(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.delegate.queryTextController.text;
    final detected = detectPalette(text);
    final paletteMatches = detected == null
        ? const <AiCommand>[]
        : AiCommands.match(detected.$1, detected.$2);

    Widget body;
    switch (widget.delegate.currentBody) {
      case .suggestions:
        body = widget.delegate.buildSuggestions(context);
      case .results:
        body = widget.delegate.buildResults(context);
      case null:
        body = const SizedBox();
    }

    return AvesScaffold(
      appBar: AppBar(
        leading: widget.delegate.buildLeading(context),
        title: const Text('Ask AI'),
        actions: widget.delegate.buildActions(context),
      ),
      body: AvesPopScope(
        handlers: [tvNavigationPopHandler, doubleBackPopHandler],
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: body),
              if (paletteMatches.isNotEmpty)
                _Palette(
                  commands: paletteMatches,
                  onTap: _insertCommand,
                ),
              _InputRow(
                controller: widget.delegate.queryTextController,
                focusNode: _inputFocus,
                onAt: () => _insertTrigger('@'),
                onSlash: () => _insertTrigger('/'),
                onPlus: () {},
                onSubmit: _onSubmit,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  final List<AiCommand> commands;
  final ValueChanged<AiCommand> onTap;

  const new({
    required this.commands,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: commands.length,
        itemBuilder: (context, i) {
          final c = commands[i];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(c.trigger, style: theme.textTheme.titleMedium),
            ),
            title: Text(c.token, style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'monospace')),
            subtitle: Text(c.description, style: theme.textTheme.bodySmall),
            onTap: () => onTap(c),
          );
        },
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAt;
  final VoidCallback onSlash;
  final VoidCallback onPlus;
  final VoidCallback onSubmit;
  final ThemeData theme;

  const new({
    required this.controller,
    required this.focusNode,
    required this.onAt,
    required this.onSlash,
    required this.onPlus,
    required this.onSubmit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RoundActionButton(
              label: '@',
              tooltip: 'Modes',
              onPressed: onAt,
              colors: colors,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Ask or type /find dog...',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            _RoundActionButton(
              label: '/',
              tooltip: 'Commands',
              onPressed: onSlash,
              colors: colors,
            ),
            const SizedBox(width: 2),
            _RoundActionButton(
              icon: Symbols.add,
              tooltip: 'Attach',
              onPressed: onPlus,
              colors: colors,
            ),
            const SizedBox(width: 2),
            _RoundActionButton(
              icon: Symbols.send,
              tooltip: 'Send',
              onPressed: onSubmit,
              colors: colors,
              accent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ColorScheme colors;
  final bool accent;

  const new({
    super.key,
    this.label,
    this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colors,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ? colors.onPrimary : colors.onSurfaceVariant;
    final bg = accent ? colors.primary : Colors.transparent;
    final child = icon != null
        ? Icon(icon, size: 22, color: fg)
        : Text(label ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fg));
    return PressableScale(
      onTap: onPressed,
      scale: 0.88,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
