import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

class CollectionSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  static const double preferredHeight = 68.0;

  const new({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.m3e;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(tokens.shapeExtraLarge * 2),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Symbols.auto_awesome, color: colors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search photos or Ask AI...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Symbols.auto_awesome, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
