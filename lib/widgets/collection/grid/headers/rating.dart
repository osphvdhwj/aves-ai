import 'package:aves/model/filters/rating.dart';
import 'package:aves/model/source/section_keys.dart';
import 'package:aves/widgets/common/grid/header.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';

class RatingSectionHeader<T> extends StatelessWidget {
  final int rating;
  final bool selectable;
  final int? count;

  const RatingSectionHeader({
    super.key,
    required this.rating,
    required this.selectable,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader<T>(
      sectionKey: EntryRatingSectionKey(rating),
      title: RatingFilter.formatRating(context, rating),
      selectable: selectable,
      leading: _buildDot(context),
      trailing: count != null ? _buildCount(context, count!) : null,
    );
  }
}


Widget _buildDot(BuildContext context) {
  return Center(
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    ),
  );
}

Widget _buildCount(BuildContext context, int count) {
  return Text(
    context.l10n.itemCount(count),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
  );
}
