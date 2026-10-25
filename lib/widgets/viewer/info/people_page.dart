import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:aves/widgets/viewer/info/person_detail_page.dart';
import 'package:material_ui/material_ui.dart';

/// People / Faces browsing surface.
///
/// UI shell: shows an empty-state until the AI companion exposes face
/// clustering. Once it does, `clusters` is populated with one entry per
/// person and the grid renders thumbnails. `routeName` is exposed so the
/// caller can register the page in the navigation layer.
class PeoplePage extends StatelessWidget {
  static const routeName = '/viewer/info/people';

  /// Face clusters from the companion. Empty until the ML pipeline ships.
  final List<FaceCluster> clusters;

  const PeoplePage({
    super.key,
    this.clusters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AvesScaffold(
      appBar: AppBar(title: const Text('People')),
      body: SafeArea(
        child: clusters.isEmpty
            ? const StatusView(
                icon: Symbols.face_6,
                title: 'No people yet',
                subtitle: 'Face clustering runs on-device in the AI companion. Once it ships, '
                    'people you appear with will be grouped here automatically.',
              )
            : _Grid(clusters: clusters),
      ),
    );
  }
}

class FaceCluster {
  final String id;
  final String? name;
  final int count;
  final ImageProvider? cover;

  const FaceCluster({
    required this.id,
    required this.count,
    this.name,
    this.cover,
  });
}

class _Grid extends StatelessWidget {
  final List<FaceCluster> clusters;

  const _Grid({required this.clusters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: clusters.length,
      itemBuilder: (context, index) {
        final c = clusters[index];
        return PressableScale(
          onTap: () => showPersonDetailPage(context, cluster: c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipOval(
                    child: c.cover != null
                        ? Image(image: c.cover!, fit: BoxFit.cover)
                        : ColoredBox(color: colors.surfaceContainerHighest),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                c.name ?? 'Unnamed',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${c.count}',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showPeoplePage(BuildContext context, {List<FaceCluster> clusters = const []}) {
  return Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: PeoplePage.routeName),
      builder: (context) => PeoplePage(clusters: clusters),
    ),
  );
}
