import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/viewer/entry_viewer_page.dart';
import 'package:aves/widgets/viewer/info/people_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

/// Detail view for one face cluster.
///
/// Grid of that person's photos plus a header with name and count. The
/// rename action is exposed as a callback so a future settings/editor
/// flow can hook in without changing this layout.
class PersonDetailPage extends StatefulWidget {
  static const routeName = '/viewer/info/person';

  final FaceCluster cluster;
  final List<AvesEntry> photos;
  final ValueChanged<String>? onRename;

  const PersonDetailPage({
    super.key,
    required this.cluster,
    this.photos = const [],
    this.onRename,
  });

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> {
  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: widget.cluster.name ?? '');
    final result = await showAvesDialog<String>(
      context: context,
      routeSettings: const RouteSettings(name: 'PersonRenameDialog'),
      builder: (context) => AvesDialog(
        title: 'Name this person',
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          CancelButton<String>(),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      widget.onRename?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final photos = widget.photos;

    return AvesScaffold(
      appBar: AppBar(
        title: Text(widget.cluster.name ?? 'Unnamed'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.edit),
            tooltip: 'Rename',
            onPressed: () => _rename(context),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: colors.surfaceContainerHighest,
                      backgroundImage: widget.cluster.cover,
                      child: widget.cluster.cover == null ? Icon(Symbols.person, size: 32, color: colors.onSurfaceVariant) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cluster.name ?? 'Unnamed',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${widget.cluster.count} photos',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (photos.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView(
                  icon: Symbols.person,
                  title: 'No photos in this cluster yet',
                ),
              )
            else
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: photos.length,
                itemBuilder: (context, i) {
                  final e = photos[i];
                  return PressableScale(
                    onTap: () => Navigator.maybeOf(context)?.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: EntryViewerPage.routeName),
                        builder: (_) => EntryViewerPage(initialEntry: e),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.m3e.shapeExtraSmall),
                      child: Image(
                        image: e.getThumbnail(extent: 256),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(color: colors.surfaceContainerHighest),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPersonDetailPage(
  BuildContext context, {
  required FaceCluster cluster,
  List<AvesEntry> photos = const [],
  ValueChanged<String>? onRename,
}) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: PersonDetailPage.routeName),
      builder: (context) => PersonDetailPage(cluster: cluster, photos: photos, onRename: onRename),
    ),
  );
}
