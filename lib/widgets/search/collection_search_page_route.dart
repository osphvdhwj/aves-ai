import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/search/ai_search_delegate.dart';
import 'package:aves/widgets/search/ai_search_page.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/search/route.dart';
import 'package:aves/widgets/search/collection_search_delegate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CollectionSearchPageRoute extends SearchPageRoute {
  new({
    required BuildContext context,
    CollectionLens? parentCollection,
    bool canPop = true,
    String? initialQuery,
  }) : super(
         delegate: settings.aiSearchEnabled
             ? AiSearchDelegate(
                 searchFieldLabel: context.l10n.searchCollectionFieldHint,
                 searchFieldStyle: Themes.searchFieldStyle(context),
                 canPop: canPop,
                 initialText: initialQuery,
               )
             : CollectionSearchDelegate(
                 searchFieldLabel: context.l10n.searchCollectionFieldHint,
                 searchFieldStyle: Themes.searchFieldStyle(context),
                 source: parentCollection?.source ?? context.read<CollectionSource>(),
                 parentCollection: parentCollection,
                 canPop: canPop,
                 initialQuery: initialQuery,
               ),
       );

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    if (settings.aiSearchEnabled && delegate is AiSearchDelegate) {
      return AiSearchPage(
        delegate: delegate as AiSearchDelegate,
        animation: animation,
      );
    }
    return super.buildPage(context, animation, secondaryAnimation);
  }
}
