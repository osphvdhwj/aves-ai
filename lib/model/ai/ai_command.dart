class AiCommand {
  final String trigger; // '/' or '@'
  final String verb;
  final String description;

  const AiCommand(this.trigger, this.verb, this.description);

  String get token => '$trigger$verb';
}

class AiCommands {
  static const all = [
    AiCommand('/', 'find', 'Search photos by description'),
    AiCommand('/', 'dup', 'Find duplicate photos'),
    AiCommand('/', 'blur', 'Find blurry photos'),
    AiCommand('/', 'receipt', 'Find receipts'),
    AiCommand('@', 'deep', 'Force deep rerank'),
    AiCommand('@', 'fast', 'Fast mode, no rerank'),
    AiCommand('@', 'ocr', 'Search text only'),
    AiCommand('@', 'person', 'Filter by face cluster'),
    AiCommand('@', 'like', 'Similar to current photo'),
  ];

  static List<AiCommand> match(String trigger, String filter) {
    final lower = filter.toLowerCase();
    return all
        .where((c) => c.trigger == trigger && (lower.isEmpty || c.verb.toLowerCase().startsWith(lower)))
        .toList();
  }
}

/// Detects a "/" or "@" trigger token in the text at the end of the string.
/// Returns (trigger, filter) or null.
(String, String)? detectPalette(String text) {
  final m = RegExp(r'(^|\s)([/@])([A-Za-z0-9_]*)$').firstMatch(text);
  if (m == null) return null;
  return (m.group(2)!, m.group(3) ?? '');
}
