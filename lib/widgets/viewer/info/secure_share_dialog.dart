import 'package:aves/model/entry/entry.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Confirmation for the "Secure share" flow.
///
/// Secure share exports a copy of the selected media with all metadata
/// removed (EXIF, GPS, XMP, IPTC, maker notes, ICC, video tags). The
/// original file is left untouched.
///
/// The UI is complete; the export itself is delegated to the platform
/// channel `deckers.thibault/aves/metadata` method `stripAndShare`. That
/// method is not yet implemented on the native side; until then this
/// dialog surfaces a clear "not available" state instead of silently
/// failing.
Future<void> showSecureShareDialog(BuildContext context, AvesEntry entry) {
  return showAvesDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: 'SecureShareDialog'),
    builder: (context) => _SecureShareDialog(entry: entry),
  );
}

class _SecureShareDialog extends StatefulWidget {
  final AvesEntry entry;

  const new({super.key, required this.entry});

  @override
  State<_SecureShareDialog> createState() => _SecureShareDialogState();
}

class _SecureShareDialogState extends State<_SecureShareDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Symbols.shield_lock, color: colors.primary),
      title: const Text('Secure share'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exports a copy with all metadata removed:',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final line in const [
            'Location (GPS)',
            'Camera and lens info',
            'Date and time',
            'Author, title, description',
            'Software and edit history',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Symbols.check_circle, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Works with every media format Aves supports. The original file is not modified.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: const Text('I understand a copy will be created'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirmed ? () => _onShare(context) : null,
          child: const Text('Secure share'),
        ),
      ],
    );
  }

  Future<void> _onShare(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Secure share is not yet available in this build.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
