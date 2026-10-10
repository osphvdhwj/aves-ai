import 'package:aves/model/filters/covered/tag.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/settings/defaults.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves_model/aves_model.dart';

mixin HistorySettings on SettingsAccess {
  static const int recentFilterHistoryMax = 20;

  void initHistorySettings() {
    vaults.lockStateChangeNotifier.addListener(_onVaultsChanged);
  }

  bool get saveSearchHistory => getBool(SettingKeys.saveSearchHistoryKey) ?? SettingsDefaults.saveSearchHistory;

  set saveSearchHistory(bool newValue) => set(SettingKeys.saveSearchHistoryKey, newValue);

  List<CollectionFilter> get searchHistory => (getStringList(SettingKeys.searchHistoryKey) ?? []).map(CollectionFilter.fromJson).nonNulls.toList();

  set searchHistory(List<CollectionFilter> newValue) => set(SettingKeys.searchHistoryKey, newValue.map((filter) => filter.toJsonString()).toList());

  // AI search history — plain-text queries, most recent first, capped.
  static const int aiSearchHistoryMax = 30;

  List<String> get aiSearchHistory => getStringList(SettingKeys.aiSearchHistoryKey) ?? [];

  set aiSearchHistory(List<String> newValue) => set(SettingKeys.aiSearchHistoryKey, newValue.take(aiSearchHistoryMax).toList());

  void addAiSearchHistory(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = aiSearchHistory
      ..remove(q)
      ..insert(0, q);
    aiSearchHistory = list;
  }

  // Saved searches — user-pinned queries, deduplicated, capped.
  static const int savedSearchesMax = 50;

  List<String> get savedSearches => getStringList(SettingKeys.savedSearchesKey) ?? [];

  set savedSearches(List<String> newValue) => set(SettingKeys.savedSearchesKey, newValue.take(savedSearchesMax).toList());

  bool isSavedSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return false;
    return savedSearches.any((s) => s == q);
  }

  void toggleSavedSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = savedSearches.toList();
    if (list.remove(q)) {
      savedSearches = list;
    } else {
      list.insert(0, q);
      savedSearches = list;
    }
  }

  void removeSavedSearch(String query) {
    savedSearches = savedSearches.where((s) => s != query).toList();
  }

  List<String> get recentSettingKeys => getStringList(SettingKeys.recentSettingKeysKey) ?? [];

  set recentSettingKeys(List<String> newValue) => set(SettingKeys.recentSettingKeysKey, newValue);

  List<String> get recentDestinationAlbums => getStringList(SettingKeys.recentDestinationAlbumsKey) ?? [];

  set recentDestinationAlbums(List<String> newValue) => set(SettingKeys.recentDestinationAlbumsKey, newValue.take(recentFilterHistoryMax).toList());

  // recent tags

  List<CollectionFilter> get _recentTags => (getStringList(SettingKeys.recentTagsKey) ?? []).map(CollectionFilter.fromJson).nonNulls.toList();

  set _recentTags(List<CollectionFilter> newValue) => set(SettingKeys.recentTagsKey, newValue.take(recentFilterHistoryMax).map((filter) => filter.toJsonString()).toList());

  // when vaults are unlocked, recent tags are transient and not persisted
  List<CollectionFilter>? _protectedRecentTags;

  List<CollectionFilter> get recentTags => vaults.needProtection ? _protectedRecentTags ?? List.of(_recentTags) : _recentTags;

  set recentTags(List<CollectionFilter> newValue) {
    if (vaults.needProtection) {
      _protectedRecentTags = newValue;
    } else {
      _recentTags = newValue;
    }
  }

  void _onVaultsChanged() => _protectedRecentTags = null;

  void removeObsoleteRecentTags(CollectionSource? source) {
    if (source != null) {
      recentTags = recentTags.where((v) => v is! TagFilter || source.sortedTags.contains(v.tag)).toList();
    }
  }
}
