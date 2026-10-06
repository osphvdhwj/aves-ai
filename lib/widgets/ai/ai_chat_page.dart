import 'dart:async';

import 'package:aves/model/ai/ai_command.dart';
import 'package:aves/model/ai/chat_message.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:material_ui/material_ui.dart';

class AiChatPage extends StatefulWidget {
  static const routeName = '/ai_chat';

  const new({super.key});

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
        duration: const Duration(milliseconds: 200),
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
      final reply = await aiService.chat(content);
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          role: ChatRole.ai,
          text: reply.error != null ? 'Error: ${reply.error}' : (reply.text.isEmpty ? '(empty reply)' : reply.text),
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
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildBubble(theme, _messages[i]),
                  ),
          ),
          _buildInputRow(theme),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ask AI', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Type /find dog or tap a preset below.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildBubble(ThemeData theme, ChatMessage m) {
    final isUser = m.role == ChatRole.user;
    final bg = isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final text = m.pending ? '...' : m.text;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: theme.textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._presets.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(p),
                          onPressed: () => _send('$p '),
                        ),
                      )),
                  ..._modifiers.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(p),
                          onPressed: () => _send(p),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(
                      hintText: 'Ask or type /find dog...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(onPressed: _send, child: const Text('Send')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
