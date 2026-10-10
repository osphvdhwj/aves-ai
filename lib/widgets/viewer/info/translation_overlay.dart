import 'package:aves/model/entry/entry.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// A single block of recognised text with its position on the media,
/// expressed as a normalized rect in `[0, 1] × [0, 1]` relative to the
/// displayed media bounds, plus its translation.
/// Parses a `@ocr.structured` reply into positioned text blocks.
///
/// The companion returns one block per line, with a normalized rect in
/// `[0,1]x[0,1]` followed by a tab and the recognised text:
///
///   `0.10	0.20	0.30	0.05\tHello world`
///   `0.10	0.30	0.40	0.06\tSecond line`
///
/// Order of the four numbers is left, top, width, height. Malformed
/// lines are skipped. When [translation] is null the source text is
/// used as the translation — useful for a first render before the
/// translate step runs.
List<TranslatedTextBlock> parseOcrBlocks(String reply, {String Function(String source)? translate}) {
  final out = <TranslatedTextBlock>[];
  for (final rawLine in reply.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final tab = line.indexOf('\t');
    if (tab <= 0) continue;
    final nums = line.substring(0, tab).split(',');
    if (nums.length != 4) continue;
    final l = double.tryParse(nums[0]);
    final t = double.tryParse(nums[1]);
    final w = double.tryParse(nums[2]);
    final h = double.tryParse(nums[3]);
    if (l == null || t == null || w == null || h == null) continue;
    final source = line.substring(tab + 1).trim();
    if (source.isEmpty) continue;
    out.add(TranslatedTextBlock(
      source: source,
      translation: translate != null ? translate(source) : source,
      rect: Rect.fromLTWH(
        l.clamp(0.0, 1.0),
        t.clamp(0.0, 1.0),
        w.clamp(0.0, 1.0),
        h.clamp(0.0, 1.0),
      ),
    ));
  }
  return out;
}

class TranslatedTextBlock {
  /// Original text as recognised by OCR.
  final String source;

  /// Translated text to display in place.
  final String translation;

  /// Position of the source text on the media, normalized.
  final Rect rect;

  const TranslatedTextBlock({
    required this.source,
    required this.translation,
    required this.rect,
  });
}

/// Renders [blocks] as translated overlays positioned over [media].
///
/// If [blocks] is empty, a short explanation is shown instead — the OCR
/// companion currently returns only text, not per-block bounding boxes.
/// Once the companion exposes boxes, filling them in is all that's needed
/// here; the positioning logic below is complete.
class TranslationOverlayDialog extends StatelessWidget {
  final AvesEntry entry;
  final Widget media;
  final List<TranslatedTextBlock> blocks;

  const new({
    super.key,
    required this.entry,
    required this.media,
    this.blocks = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Translation'),
      ),
      body: SafeArea(
        child: blocks.isEmpty
            ? _EmptyState(entry: entry)
            : _Overlay(media: media, blocks: blocks),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  final Widget media;
  final List<TranslatedTextBlock> blocks;

  const new({required this.media, required this.blocks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InteractiveViewer(
      minScale: 1,
      maxScale: 6,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                media,
                for (final b in blocks)
                  Positioned(
                    left: b.rect.left * w,
                    top: b.rect.top * h,
                    width: b.rect.width * w,
                    height: b.rect.height * h,
                    child: PressableScale(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Original: ${b.source}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(context.m3e.shapeSmall),
                          border: Border.all(color: colors.outlineVariant, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            b.translation,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AvesEntry entry;

  const new({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.translate, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'In-place translation needs OCR bounding boxes.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'The AI companion currently returns recognised text without positions, '
            'so translated text cannot yet be placed over the original layout.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Opens the translation overlay. Blocks must come from the OCR companion;
/// this helper exists so the call site is in place.
Future<void> showTranslationOverlay(
  BuildContext context, {
  required AvesEntry entry,
  required Widget media,
  List<TranslatedTextBlock> blocks = const [],
}) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'TranslationOverlayPage'),
      builder: (context) => TranslationOverlayDialog(entry: entry, media: media, blocks: blocks),
    ),
  );
}
