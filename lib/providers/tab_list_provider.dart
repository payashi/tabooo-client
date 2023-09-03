import 'package:tab_organizer/chrome_api.dart';
import 'package:tab_organizer/models/chrome_tab.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TabListNotifier extends StateNotifier<AsyncValue<List<ChromeTab>>> {
  TabListNotifier() : super(const AsyncValue.loading()) {
    _fetch();
  }

  Future<void> _fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => queryTabs(QueryOptions()));
  }
}

final tabListProvider =
    StateNotifierProvider<TabListNotifier, AsyncValue<List<ChromeTab>>>(
        (ref) => TabListNotifier());