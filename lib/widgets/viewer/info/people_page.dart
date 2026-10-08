import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
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

  const new({
    super.key,
    this.clusters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: SafeArea(
        child: clusters.isEmpty ? const _EmptyState() : _Grid(clusters: clusters),
      ),
    );
  }
}

class FaceCluster {
  final String id;
  final String? name;
  final int count;
  final ImageProvider? cover;

  const new({
    required this.id,
    required this.count,
    this.name,
    this.cover,
  });
}

class _Grid extends StatelessWidget {
  final List<FaceCluster> clusters;

  const new({required this.clusters});

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

class _EmptyState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.face_6, size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 20),
          Text(
            'No people yet',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Face clustering runs on-device in the AI companion. Once it ships, '
            'people you appear with will be grouped here automatically.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Future<void> showPeoplePage(BuildContext context, {List<FaceCluster> clusters = const []}) async {
  final tokens = context.m3e;
  await Navigator.maybeOf(context)?.push(
    PageRouteBuilder(
      settings: const RouteSettings(name: PeoplePage.routeName),
      transitionDuration: tokens.durationMedium2,
      reverseTransitionDuration: tokens.durationMedium2,
      pageBuilder: (context, _, _) => PeoplePage(clusters: clusters),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}
