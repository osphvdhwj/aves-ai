import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Google Photos sign-in consent dialog.
///
/// Explains what will be read and written, and requires an explicit
/// confirmation. The actual OAuth flow lives outside this repo (it
/// needs a registered client ID and a native sign-in bridge), so the
/// confirm action currently reports that the flow is not yet available.
Future<void> showSyncSigninDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _SyncSigninDialog(),
  );
}

class _SyncSigninDialog extends StatefulWidget {
  const _SyncSigninDialog();

  @override
  State<_SyncSigninDialog> createState() => _SyncSigninDialogState();
}

class _SyncSigninDialogState extends State<_SyncSigninDialog> {
  bool _consent = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Symbols.cloud_sync, color: colors.primary),
      title: const Text('Sign in to back up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aves will be able to:',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final line in const [
            'Upload originals and edits',
            'Manage albums and favourites',
            'Read EXIF and location to keep them in sync',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Symbols.check, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Aves never sells data and never uses your library for advertising.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: const Text('I agree to the above'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _consent
              ? () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(context).maybePop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sign-in is not yet available in this build.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
