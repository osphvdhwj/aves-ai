import 'package:aves/services/common/channel.dart';
import 'package:aves/services/common/services.dart';

class AiService {
  static const _platform = AvesMethodChannel('deckers.thibault/aves/ai');

  Future<AiHealth> health() async {
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
    } catch (e, s) {
      log('failed to query AI companion health', error: e, stackTrace: s);
      return const AiHealth(installed: false, connected: false);
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

  @override
  String toString() => 'AiHealth(installed: $installed, connected: $connected, apiVersion: $apiVersion, capabilities: $capabilities, error: $error)';
}

final aiService = AiService();
