import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// MIUI-style "text form" view: the media is shown with its recognised
/// text laid out as real selectable text on top, so the user can long-press
/// a word, drag handles, and copy — exactly like selecting text in a browser.
///
/// The recognition itself comes from the AI companion via `@ocr`. The
/// per-block positions are not yet returned by the companion, so blocks
/// are stacked below the image and remain fully selectable. Once the
/// companion exposes bounding boxes, only [TranslatedTextBlock.rect]
/// rendering needs to be swapped in.
class TextSelectPage extends StatefulWidget {
  static const routeName = '/viewer/info/text_select';

  final AvesEntry entry;

  const TextSelectPage({super.key, required this.entry});

  @override
  State<TextSelectPage> createState() => _TextSelectPageState();
}

class _TextSelectPageState extends State<TextSelectPage> {
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
    final entry = widget.entry;
    return AvesScaffold(
      appBar: AppBar(
        title: const Text('Select text'),
        actions: [
          FutureBuilder<AiChatReply>(
            future: _future,
            builder: (context, snapshot) {
              final text = snapshot.data?.text.trim() ?? '';
              return IconButton(
                icon: const Icon(Symbols.content_copy),
                tooltip: 'Copy all',
                onPressed: text.isEmpty
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final copied = await appService.copyToClipboard(text: text);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(copied ? 'Copied' : 'Copy failed'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // the image, browser-like, above the selectable text
            AspectRatio(
              aspectRatio: entry.displaySize.aspectRatio,
              child: Image(
                image: entry.getThumbnail(extent: 512),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<AiChatReply>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reply = snapshot.data;
                  final error = reply?.error;
                  final text = reply?.text.trim() ?? '';
                  if (reply?.isModelMissing == true) {
                    return _status('OCR model missing', subtitle: 'The AVES+ Tools companion does not have its OCR model installed yet.', isError: true);
                  }
                  if (reply?.isUnsupported == true) {
                    return _status('Update required', subtitle: 'This companion build does not support OCR. Update AVES+ Tools.', isError: true);
                  }
                  if (error != null && error.isNotEmpty) {
                    return _status('Text recognition failed', subtitle: error, isError: true);
                  }
                  if (text.isEmpty) {
                    return _status('No text detected in this image.');
                  }
                  // SelectionSurface enables the browser-like long-press
                  // drag-select affordance over the recognised text.
                  return SelectionArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(String title, {String? subtitle, bool isError = false}) {
    return StatusView(
      icon: isError ? AIcons.error : Symbols.text_fields,
      title: title,
      subtitle: subtitle,
      isError: isError,
    );
  }
}

/// Opens [TextSelectPage] with a shared-element-ish fade transition.
Future<void> showTextSelectPage(BuildContext context, AvesEntry entry) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: TextSelectPage.routeName),
      builder: (context) => TextSelectPage(entry: entry),
    ),
  );
}
