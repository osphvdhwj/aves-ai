import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/images.dart';
import 'package:aves/services/ai_service.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/pressable_scale.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/basic/status_view.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:aves/widgets/viewer/info/person_detail_page.dart';
import 'package:material_ui/material_ui.dart';

/// People / Faces browsing surface, powered by the companion's /faces
/// command: MobileFaceNet embeddings clustered by the companion at
/// cosine >= 0.6, groups reported with [AiChatReply.groupSizes].
///
/// Without the companion the page shows an honest empty state. Clusters
/// can also be injected directly via [clusters] (used by callers that
/// already ran the scan).
class PeoplePage extends StatefulWidget {
  static const routeName = '/viewer/info/people';

  /// Entries the face scan runs over. Capped by the caller: embedding is
  /// one MobileFaceNet inference per photo.
  final List<AvesEntry> entries;

  /// Pre-computed clusters; when empty the page runs the scan itself.
  final List<FaceCluster> clusters;

  const PeoplePage({
    super.key,
    this.entries = const [],
    this.clusters = const [],
  });

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  /// Cap for the companion pass: /faces embeds every payload entry.
  static const _companionPayloadCap = 200;

  late List<FaceCluster> _clusters;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clusters = widget.clusters;
    if (_clusters.isEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await aiService.hasCapability('faces')) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final payload = widget.entries.take(_companionPayloadCap).toList();
      final reply = await aiService.chat(
        '/faces',
        entryIds: payload.map((e) => e.id).toList(),
        entries: AiService.entriesPayload(payload),
      );
      if (!mounted) return;
      final error = reply.error;
      if (error != null && error.isNotEmpty) {
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }
      final byId = {for (final e in payload) e.id: e};
      final clusters = <FaceCluster>[];
      var index = 0;
      for (final ids in reply.groupedEntryIds) {
        final photos = ids.map((id) => byId[id]).whereType<AvesEntry>().toList();
        if (photos.isEmpty) continue;
        final coverEntry = photos.first;
        clusters.add(FaceCluster(
          id: 'cluster-$index',
          name: 'Person ${index + 1}',
          count: photos.length,
          cover: coverEntry.getThumbnail(extent: 256),
          photos: photos,
        ));
        index++;
      }
      setState(() {
        _clusters = clusters;
        _loading = false;
      });
    } catch (e, s) {
      await reportService.recordError(e, s);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AvesScaffold(
      appBar: AppBar(title: const Text('People')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? StatusView(
                    icon: AIcons.error,
                    isError: true,
                    title: 'Face scan failed',
                    subtitle: _error,
                  )
                : _clusters.isEmpty
                    ? const StatusView(
                        icon: Symbols.face_6,
                        title: 'No people found',
                        subtitle: 'The companion looked for repeated faces in your photos and '
                            'found none it could group. Portraits and selfies work best.',
                      )
                    : _Grid(clusters: _clusters),
      ),
    );
  }
}

class FaceCluster {
  final String id;
  final String? name;
  final int count;
  final ImageProvider? cover;
  final List<AvesEntry> photos;

  const FaceCluster({
    required this.id,
    required this.count,
    this.name,
    this.cover,
    this.photos = const [],
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
          onTap: () => showPersonDetailPage(context, cluster: c, photos: c.photos),
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

Future<void> showPeoplePage(BuildContext context, {List<AvesEntry> entries = const [], List<FaceCluster> clusters = const []}) async {
  await Navigator.maybeOf(context)?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: PeoplePage.routeName),
      builder: (context) => PeoplePage(entries: entries, clusters: clusters),
    ),
  );
}
