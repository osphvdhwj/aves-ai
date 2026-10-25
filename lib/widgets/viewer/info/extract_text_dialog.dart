import 'dart:typed_data';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/search/route.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/search/ai_search_delegate.dart';
import 'package:aves/widgets/viewer/info/translation_overlay.dart';
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

  const _ExtractTextDialog({super.key, required this.entry});

  @override
  State<_ExtractTextDialog> createState() => _ExtractTextDialogState();
}

class _ExtractTextDialogState extends State<_ExtractTextDialog> {
  late final Future<AiChatReply> _future;

  @override
  void initState() {
    super.initState();
    _future = aiService.chat(
      '@ocr',
      entryIds: [widget.entry.id],
      entries: AiService.entriesPayload([widget.entry]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FutureBuilder<AiChatReply>(
      future: _future,
      builder: (context, snapshot) {
        final reply = snapshot.data;
        final text = reply?.text.trim() ?? '';
        final hasText = text.isNotEmpty;
        return AvesDialog(
          title: 'Extract text',
          content: SizedBox(
            width: 360,
            child: snapshot.connectionState != ConnectionState.done
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _content(theme, colors, reply, hasText: hasText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: hasText ? () => _copy(context, text, message: 'Text copied') : null,
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: hasText
                  ? () async {
                      final navigator = Navigator.of(context);
                      await _copy(context, text, message: 'Text copied — paste it into your translation app.');
                      navigator.maybePop();
                    }
                  : null,
              child: const Text('Translate'),
            ),
            TextButton(
              onPressed: hasText
                  ? () {
                      final blocks = parseOcrBlocks(text);
                      Navigator.of(context).maybePop();
                      showTranslationOverlay(
                        context,
                        entry: widget.entry,
                        media: Image(
                          image: widget.entry.getThumbnail(extent: 1024),
                          fit: BoxFit.contain,
                        ),
                        blocks: blocks,
                      );
                    }
                  : null,
              child: const Text('In place'),
            ),
            TextButton(
              onPressed: hasText
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final saved = await storageService.createFile(
                        basename: 'ocr-${widget.entry.id}',
                        mimeType: 'text/plain',
                        bytes: Uint8List.fromList(text.codeUnits),
                        reportErrors: true,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(saved == true ? 'Saved' : 'Not saved'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: const Text('Save .txt'),
            ),
            TextButton(
              onPressed: hasText
                  ? () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).push(
                        SearchPageRoute(
                          delegate: AiSearchDelegate(
                            searchFieldLabel: 'Find in text',
                            searchFieldStyle: Themes.searchFieldStyle(context),
                            initialText: text,
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Find'),
            ),
          ],
        );
      },
    );
  }

  Widget _content(ThemeData theme, ColorScheme colors, AiChatReply? reply, {required bool hasText}) {
    final error = reply?.error;
    final text = reply?.text.trim() ?? '';
    if (reply?.isModelMissing == true) {
      return _message(theme, colors, 'The AVES+ Tools companion does not have its OCR model installed yet.');
    }
    if (reply?.isUnsupported == true) {
      return _message(theme, colors, 'This companion build does not support OCR. Update AVES+ Tools.');
    }
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
  }

  Future<void> _copy(BuildContext context, String text, {required String message}) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = await appService.copyToClipboard(text: text);
    messenger.showSnackBar(
      SnackBar(
        content: Text(copied ? message : 'Copy failed'),
        duration: const Duration(seconds: 2),
      ),
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
