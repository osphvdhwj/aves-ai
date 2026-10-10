import 'dart:ui';

import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/behaviour/pop/double_back.dart';
import 'package:aves/widgets/common/behaviour/pop/scope.dart';
import 'package:aves/widgets/common/behaviour/pop/tv_navigation.dart';
import 'package:aves/widgets/common/search/page.dart';
import 'package:aves/widgets/search/ai_search_delegate.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

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
    final colors = theme.colorScheme;
    final m3e = context.m3e;
    final isMode = commands.isNotEmpty && commands.first.trigger == '@';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(m3e.shapeExtraLarge - 4)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              children: [
                Icon(Symbols.keyboard_command_key, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  isMode ? 'MODES' : 'COMMANDS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: commands.length,
              itemBuilder: (context, i) {
                final c = commands[i];
                return PressableScale(
                  onTap: () => onTap(c),
                  scale: 0.98,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(m3e.shapeMedium),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            c.trigger,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.token,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                c.description,
                                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
    final m3e = context.m3e;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(m3e.shapeExtraLarge),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RoundActionButton(
              icon: Symbols.add,
              tooltip: 'Attach',
              onPressed: onPlus,
              colors: colors,
              subtle: true,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Ask, or type /find or @mode',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            _TokenChip(label: '/', onTap: onSlash, colors: colors),
            const SizedBox(width: 6),
            _TokenChip(label: '@', onTap: onAt, colors: colors),
            const SizedBox(width: 6),
            _RoundActionButton(
              icon: Symbols.arrow_upward,
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

class _TokenChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colors;

  const new({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final m3e = context.m3e;
    return PressableScale(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(m3e.shapeMedium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
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
  final bool subtle;

  const new({
    super.key,
    this.label,
    this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colors,
    this.accent = false,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ? colors.onPrimary : colors.onSurfaceVariant;
    final bg = accent
        ? colors.primary
        : (subtle ? colors.surfaceContainerHighest : Colors.transparent);
    final size = accent ? 44.0 : 40.0;
    final child = icon != null
        ? Icon(icon, size: 22, color: fg)
        : Text(label ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fg));
    return PressableScale(
      onTap: onPressed,
      scale: 0.88,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
