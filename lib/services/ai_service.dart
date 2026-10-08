import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

class AiService {
  static const _platform = AvesMethodChannel('deckers.thibault/aves/ai');

  // Session cache: the companion's health does not change during a
  // session, so one probe per app launch is enough. Use forceRefresh
  // after installing/updating the companion.
  Future<AiHealth>? _healthFuture;

  Future<AiHealth> health({bool forceRefresh = false}) {
    if (forceRefresh || _healthFuture == null) {
      _healthFuture = _probeHealth();
    }
    return _healthFuture!;
  }

  /// Convenience check. Same caching as [health].
  Future<bool> hasCapability(String capability) async {
    final h = await health();
    return h.connected && h.has(capability);
  }

  Future<AiHealth> _probeHealth() async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('health');
      if (result == null) return const AiHealth(installed: false, connected: false);
      final map = result.cast<String, dynamic>();
      return AiHealth(
        installed: map['installed'] == true,
        connected: map['connected'] == true,
        apiVersion: map['apiVersion'] as int?,
        capabilities: (map['capabilities'] as List?)?.cast<String>() ?? const [],
        error: map['error'] as String?,
      );
    } on PlatformException catch (e, s) {
      await reportService.recordError(e, s);
      return AiHealth(installed: false, connected: false, error: e.message);
    }
  }

  Future<AiChatReply> chat(String text, {List<int> entryIds = const []}) async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>('chat', {
        'text': text,
        'entryIds': entryIds,
      });
      if (result == null) return const AiChatReply(text: '', error: 'no reply');
      final map = result.cast<String, dynamic>();
      return AiChatReply(
        text: (map['text'] as String?) ?? '',
        entryIds: (map['entryIds'] as List?)?.cast<int>() ?? const [],
        error: map['errorMessage'] as String?,
      );
    } on PlatformException catch (e, s) {
      await reportService.recordError(e, s);
      return AiChatReply(text: '', error: e.message ?? e.code);
    }
  }
}

class AiHealth {
  final bool installed;
  final bool connected;
  final int? apiVersion;
  final List<String> capabilities;
  final String? error;

  const AiHealth({
    required this.installed,
    required this.connected,
    this.apiVersion,
    this.capabilities = const [],
    this.error,
  });

  /// Whether the companion advertised the given capability id, e.g.
  /// `'nsfw'`, `'ocr'`, `'person'`, `'objects'`, `'translate'`.
  bool has(String capability) => capabilities.contains(capability);

  @override
  String toString() => 'AiHealth(installed: $installed, connected: $connected, apiVersion: $apiVersion, capabilities: $capabilities, error: $error)';
}

class AiChatReply {
  final String text;
  final List<int> entryIds;
  final String? error;

  const AiChatReply({
    required this.text,
    this.entryIds = const [],
    this.error,
  });
}

final aiService = AiService();
