import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/nsfw_tags.dart';

/// A single proposed tag with its source and confidence.
class TagProposal {
  final String tag;
  final String source; // e.g. 'album', 'path', 'filename', 'mime', 'nsfw-vocabulary'
  final double confidence; // 0.0 – 1.0

  const TagProposal({required this.tag, required this.source, required this.confidence});
}

/// Rule-based auto-tagger that derives tag candidates from an entry's
/// metadata alone. No image content is inspected — every rule is a
/// deterministic function of the entry's fields.
///
/// The engine is intentionally composable: each rule is a plain function
/// taking an [AvesEntry] and returning zero or more [TagProposal]s. Add
/// rules to [AutoTagger.defaultRules] to extend coverage.
class AutoTagger {
  /// A single classification rule.
  ///
  /// Rules must be cheap (no I/O) and deterministic. They may consult the
  /// entry's tags, album path, filename, mime type, dimensions, dates, and
  /// GPS location.
  final List<List<TagProposal> Function(AvesEntry)> rules;

  AutoTagger({List<List<TagProposal> Function(AvesEntry)>? rules}) : rules = rules ?? defaultRules;

  /// Proposes tags for [entry], deduplicated by tag name with the highest
  /// confidence kept.
  List<TagProposal> propose(AvesEntry entry) {
    final byTag = <String, TagProposal>{};
    for (final rule in rules) {
      for (final p in rule(entry)) {
        final existing = byTag[p.tag];
        if (existing == null || p.confidence > existing.confidence) {
          byTag[p.tag] = p;
        }
      }
    }
    final list = byTag.values.toList();
    list.sort((a, b) => b.confidence.compareTo(a.confidence));
    return list;
  }

  /// Proposals not already present on [entry].
  List<TagProposal> proposeNew(AvesEntry entry) {
    final existing = entry.tags.map((t) => t.toLowerCase()).toSet();
    return propose(entry).where((p) => !existing.contains(p.tag.toLowerCase())).toList();
  }

  static List<List<TagProposal> Function(AvesEntry)> get defaultRules => const [
        _albumSegments,
        _pathTokens,
        _filenameTokens,
        _nsfwVocabulary,
        _mimeCategory,
        _orientation,
        _aspectRatio,
        _videoDuration,
        _imageSize,
        _timeOfDay,
        _weekday,
        _season,
        _decade,
        _location,
      ];

  // ── helpers ────────────────────────────────────────────────────────

  static Iterable<String> _splitPath(String path) sync* {
    for (final raw in path.split('/')) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      for (final tok in _splitTokens(t)) {
        yield tok;
      }
    }
  }

  static Iterable<String> _splitTokens(String s) sync* {
    final spaced = s
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ');
    for (final t in spaced.split(' ')) {
      final w = t.trim().toLowerCase();
      if (w.length < 3) continue;
      if (w.length > 24) continue;
      if (int.tryParse(w) != null) continue;
      yield w;
    }
  }

  static const _genericSegments = {
    'camera', 'dcim', 'download', 'downloads', 'pictures', 'photos',
    'images', 'screenshots', 'screenshot', 'movies', 'videos', 'video',
    'internal', 'storage', 'emulated', '0', 'sdcard', 'android',
    'whatsapp', 'telegram', 'signal', 'instagram', 'facebook', 'messenger',
    'snapchat', 'tiktok', 'twitter', 'reddit', 'pinterest',
    'img', 'image', 'vid', 'photo', 'pic', 'thumbnails',
    'original', 'edited', 'export', 'exports', 'shared', 'sent', 'received',
    'backup', 'backups', 'restore', 'recovered', 'trash', 'temp', 'tmp',
  };

  // ── rules ──────────────────────────────────────────────────────────

  /// Album segments become tags ("Vacation 2023" → "vacation", "2023").
  static List<TagProposal> _albumSegments(AvesEntry entry) {
    final dir = entry.directory;
    if (dir == null || dir.isEmpty) return const [];
    final segments = dir.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return const [];
    final album = segments.last.trim();
    if (_genericSegments.contains(album.toLowerCase())) return const [];
    final tokens = _splitTokens(album).where((t) => !_genericSegments.contains(t));
    return tokens.map((t) => TagProposal(tag: t, source: 'album', confidence: 0.6)).toList();
  }

  /// Non-generic path segments become tags at lower confidence.
  static List<TagProposal> _pathTokens(AvesEntry entry) {
    final dir = entry.directory;
    if (dir == null || dir.isEmpty) return const [];
    final out = <TagProposal>[];
    for (final t in _splitPath(dir)) {
      if (_genericSegments.contains(t)) continue;
      out.add(TagProposal(tag: t, source: 'path', confidence: 0.35));
    }
    return out;
  }

  /// Filename tokens become tags at low confidence.
  static List<TagProposal> _filenameTokens(AvesEntry entry) {
    final title = entry.bestTitle ?? '';
    final tokens = _splitTokens(title).where((t) => !_genericSegments.contains(t));
    return tokens.map((t) => TagProposal(tag: t, source: 'filename', confidence: 0.2)).toList();
  }

  /// Any token that appears in the bundled NSFW vocabulary gets boosted.
  static List<TagProposal> _nsfwVocabulary(AvesEntry entry) {
    if (NsfwTags.cached == null) return const [];
    final out = <TagProposal>[];
    final seen = <String>{};
    void check(String s, String source, double conf) {
      for (final t in _splitTokens(s)) {
        if (NsfwTags.contains(t) && seen.add(t)) {
          out.add(TagProposal(tag: t, source: source, confidence: conf));
        }
      }
    }

    for (final t in entry.tags) {
      if (NsfwTags.contains(t) && seen.add(t.toLowerCase())) {
        out.add(TagProposal(tag: t, source: 'nsfw-vocabulary', confidence: 1.0));
      }
    }
    final dir = entry.directory ?? '';
    check(dir, 'nsfw-vocabulary', 0.9);
    check(entry.bestTitle ?? '', 'nsfw-vocabulary', 0.8);
    return out;
  }

  /// Category tag from mime type.
  static List<TagProposal> _mimeCategory(AvesEntry entry) {
    if (entry.isVideo) return const [TagProposal(tag: 'video', source: 'mime', confidence: 0.7)];
    if (entry.isSvg) return const [TagProposal(tag: 'vector', source: 'mime', confidence: 0.7)];
    if (entry.isRaw) return const [TagProposal(tag: 'raw', source: 'mime', confidence: 0.7)];
    if (entry.isImage) return const [TagProposal(tag: 'photo', source: 'mime', confidence: 0.5)];
    return const [];
  }

  /// Orientation tag.
  static List<TagProposal> _orientation(AvesEntry entry) {
    if (!entry.isSized) return const [];
    if (entry.width == entry.height) {
      return const [TagProposal(tag: 'square', source: 'orientation', confidence: 0.5)];
    }
    if (entry.width > entry.height) {
      return const [TagProposal(tag: 'landscape', source: 'orientation', confidence: 0.5)];
    }
    return const [TagProposal(tag: 'portrait', source: 'orientation', confidence: 0.5)];
  }

  /// Coarse aspect-ratio bucket.
  static List<TagProposal> _aspectRatio(AvesEntry entry) {
    if (!entry.isSized || entry.height == 0) return const [];
    final r = entry.width / entry.height;
    if (r >= 2.2) return const [TagProposal(tag: 'panorama', source: 'aspect', confidence: 0.4)];
    if (r >= 1.7 && r <= 1.85) return const [TagProposal(tag: 'widescreen', source: 'aspect', confidence: 0.3)];
    return const [];
  }

  /// Duration buckets for video.
  static List<TagProposal> _videoDuration(AvesEntry entry) {
    if (!entry.isVideo) return const [];
    final ms = entry.durationMillis;
    if (ms == null || ms <= 0) return const [];
    final s = ms ~/ 1000;
    if (s <= 5) return const [TagProposal(tag: 'clip', source: 'duration', confidence: 0.4)];
    if (s >= 1200) return const [TagProposal(tag: 'long-video', source: 'duration', confidence: 0.4)];
    return const [];
  }

  /// Image megapixel bucket.
  static List<TagProposal> _imageSize(AvesEntry entry) {
    if (!entry.isImage || !entry.isSized) return const [];
    final mp = (entry.width * entry.height) / 1000000;
    if (mp >= 20) return const [TagProposal(tag: 'high-resolution', source: 'size', confidence: 0.4)];
    if (mp > 0 && mp < 1) return const [TagProposal(tag: 'low-resolution', source: 'size', confidence: 0.5)];
    return const [];
  }

  /// Time-of-day bucket.
  static List<TagProposal> _timeOfDay(AvesEntry entry) {
    final d = entry.bestDate;
    if (d == null) return const [];
    final h = d.hour;
    if (h >= 5 && h < 12) return const [TagProposal(tag: 'morning', source: 'time', confidence: 0.35)];
    if (h >= 12 && h < 17) return const [TagProposal(tag: 'afternoon', source: 'time', confidence: 0.35)];
    if (h >= 17 && h < 21) return const [TagProposal(tag: 'evening', source: 'time', confidence: 0.35)];
    return const [TagProposal(tag: 'night', source: 'time', confidence: 0.4)];
  }

  /// Weekday bucket.
  static List<TagProposal> _weekday(AvesEntry entry) {
    final d = entry.bestDate;
    if (d == null) return const [];
    const names = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return [TagProposal(tag: names[d.weekday - 1], source: 'weekday', confidence: 0.25)];
  }

  /// Season bucket (northern hemisphere).
  static List<TagProposal> _season(AvesEntry entry) {
    final d = entry.bestDate;
    if (d == null) return const [];
    final m = d.month;
    if (m == 12 || m <= 2) return const [TagProposal(tag: 'winter', source: 'season', confidence: 0.3)];
    if (m <= 5) return const [TagProposal(tag: 'spring', source: 'season', confidence: 0.3)];
    if (m <= 8) return const [TagProposal(tag: 'summer', source: 'season', confidence: 0.3)];
    return const [TagProposal(tag: 'autumn', source: 'season', confidence: 0.3)];
  }

  /// Decade tag.
  static List<TagProposal> _decade(AvesEntry entry) {
    final d = entry.bestDate;
    if (d == null) return const [];
    final dec = (d.year ~/ 10) * 10;
    return [TagProposal(tag: '${dec}s', source: 'decade', confidence: 0.2)];
  }

  /// Location presence flag (does not reverse-geocode).
  static List<TagProposal> _location(AvesEntry entry) {
    if (!entry.hasGps) return const [];
    return const [TagProposal(tag: 'geo-tagged', source: 'location', confidence: 0.3)];
  }
}
