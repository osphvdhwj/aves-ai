import 'dart:async';

import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/ai/chat_message.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class AiChatPage extends StatefulWidget {
  static const routeName = '/ai_chat';

  /// When provided, every message carries this entry's media so the
  /// companion can act on the photo the user was looking at. When
  /// null (opened from the drawer), chat is text-only.
  final AvesEntry? entry;

  const new({super.key, this.entry});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static List<String> get _presets =>
      AiCommands.all.where((c) => c.trigger == '/').map((c) => c.token).toList();
  static List<String> get _modifiers =>
      AiCommands.all.where((c) => c.trigger == '@').map((c) => c.token).toList();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      unawaited(_scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ));
    });
  }

  void _send([String? text]) {
    final content = (text ?? _input.text).trim();
    if (content.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, text: content));
      _messages.add(const ChatMessage(role: ChatRole.ai, text: '', pending: true));
    });
    _input.clear();
    _scrollToBottom();

    () async {
      final entry = widget.entry;
      final reply = await aiService.chat(
        content,
        entryIds: entry != null ? [entry.id] : const [],
        entries: entry != null ? AiService.entriesPayload([entry]) : const [],
      );
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        final body = reply.isModelMissing
            ? 'The companion is missing a required model. Install it in AVES+ Tools.'
            : reply.isUnsupported
                ? 'This companion build does not support that command. Update AVES+ Tools.'
                : reply.error != null
                    ? 'Error: ${reply.error}'
                    : (reply.text.isEmpty ? '(empty reply)' : reply.text);
        _messages.add(ChatMessage(
          role: ChatRole.ai,
          text: body,
          entryIds: reply.entryIds,
        ));
      });
      _scrollToBottom();
    }();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AvesScaffold(
      appBar: AppBar(
        title: const Text('Ask AI'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: () => setState(_messages.clear),
              icon: const Icon(Symbols.delete),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty(theme)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildBubble(theme, _messages[i]),
                  ),
          ),
          _buildInputRow(theme),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Symbols.auto_awesome, size: 32, color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask AI about your photos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try /find dog, /receipt, or @ocr. Tap a preset below to start.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ThemeData theme, ChatMessage m) {
    final isUser = m.role == ChatRole.user;
    final colors = theme.colorScheme;
    final bg = isUser ? colors.primaryContainer : colors.surfaceContainerHigh;
    final fg = isUser ? colors.onPrimaryContainer : colors.onSurface;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isUser ? context.m3e.shapeLarge : 4),
      topRight: Radius.circular(isUser ? 4 : context.m3e.shapeLarge),
      bottomLeft: Radius.circular(context.m3e.shapeLarge),
      bottomRight: Radius.circular(context.m3e.shapeLarge),
    );

    final child = m.pending
        ? const _TypingIndicator()
        : Text(
            m.text,
            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
          );

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Symbols.auto_awesome, size: 16, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radius,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    final colors = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _presets)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PressableScale(
                        onTap: () => _send('$p '),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 8),
                          ),
                          child: Text(
                            p,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (final p in _modifiers)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PressableScale(
                        onTap: () => _send(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 8),
                          ),
                          child: Text(
                            p,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(context.m3e.shapeExtraLarge - 8),
                    ),
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ask or type /find dog, videos, gifs...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Symbols.arrow_upward, color: colors.onPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Three pulsing dots shown while the companion is computing a reply.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctl.value + i * 0.33) % 1.0;
            final opacity = (0.3 + 0.7 * (0.5 + 0.5 * (1 - (2 * phase - 1).abs()))).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
