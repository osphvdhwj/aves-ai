enum ChatRole { user, ai }

class ChatMessage {
  final ChatRole role;
  final String text;
  final List<int> entryIds;
  final bool pending;

  const ChatMessage({
    required this.role,
    required this.text,
    this.entryIds = const [],
    this.pending = false,
  });
}
