import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the OCR result for [entry] in a dialog with a copy action.
///
/// Routes through the AI companion (`aiService.chat('@ocr', entryIds: …)`).
/// If the companion is not installed or does not advertise OCR, the dialog
/// surfaces the error rather than failing silently.
Future<void> showExtractTextDialog(BuildContext context, AvesEntry entry) {
  return showAvesDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: 'ExtractTextDialog'),
    builder: (context) => _ExtractTextDialog(entry: entry),
  );
}

class _ExtractTextDialog extends StatefulWidget {
  final AvesEntry entry;

  const new({super.key, required this.entry});

  @override
  State<_ExtractTextDialog> createState() => _ExtractTextDialogState();
}

class _ExtractTextDialogState extends State<_ExtractTextDialog> {
  late final Future<AiChatReply> _future;

  @override
  void initState() {
    super.initState();
    _future = aiService.chat('@ocr', entryIds: [widget.entry.id]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: const Text('Extract text'),
      content: SizedBox(
        width: 360,
        child: FutureBuilder<AiChatReply>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final reply = snapshot.data;
            final error = reply?.error;
            final text = reply?.text.trim() ?? '';
            if (error != null && error.isNotEmpty) {
              return _message(theme, colors, 'Text extraction failed: $error');
            }
            if (text.isEmpty) {
              return _message(theme, colors, 'No text detected in this image.');
            }
            return SingleChildScrollView(
              child: SelectableText(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Close'),
        ),
        FutureBuilder<AiChatReply>(
          future: _future,
          builder: (context, snapshot) {
            final text = snapshot.data?.text.trim() ?? '';
            final enabled = text.isNotEmpty;
            return TextButton.icon(
              onPressed: enabled
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final copied = await appService.copyToClipboard(text: text);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(copied ? 'Text copied' : 'Copy failed'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Symbols.content_copy, size: 18),
              label: const Text('Copy'),
            );
          },
        ),
      ],
    );
  }

  Widget _message(ThemeData theme, ColorScheme colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
