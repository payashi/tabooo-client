import 'dart:js_interop';

import 'package:tab_organizer/chrome_api.dart';
import 'package:tab_organizer/models/category_info.dart';
import 'package:tab_organizer/models/chrome_tab.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:dio/dio.dart';

const apiUrl = "https://tabooo-api-s2tocqio2a-an.a.run.app";

class CategoryInfoNotifier extends StateNotifier<AsyncValue<CategoryInfo>> {
  static final dio = Dio();

  CategoryInfoNotifier() : super(const AsyncValue.loading()) {
    fetchTabs();
  }

  Future<void> fetchTabs() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => queryTabs(
          TabsQueryInfo(windowType: 'normal'),
        ));
  }

  Future<void> classify() async {
    if (state.value == null) return;

    // The state must be CategoryInfo when calling API
    final tabs = state.value!.tabs.entries.fold<List<ChromeTab>>(
      [],
      (acc, el) => [...acc, ...el.value],
    );

    state = const AsyncValue.loading();

    try {
      Response<Map<String, dynamic>> response = await dio.post(
        '$apiUrl/classify',
        data: {'urls': tabs.map((tab) => tab.url).toList()},
        options: Options(
          headers: {
            // 'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      final Map<String, List<String>> results =
          response.data!.map((k, v) => MapEntry(k, v));

      int unclassified = -1;

      // Fill Category field to each Url
      for (var entry in results.entries) {
        final filteredTabs =
            tabs.where((tab) => entry.value.contains(tab.url)).toList();
        filteredTabs.sort((a, b) => a.url.compareTo(b.url));

        final tabIds = filteredTabs.map((tab) => tab.id).toList();
        final groupId = await groupTabs(TabsGroupOptions(
          tabIds: tabIds,
          createProperties: TabsGroupOptionsCreateProperties(
            windowId: filteredTabs.first.windowId,
          ),
        ));
        await updateTabGroups(
          groupId,
          TabGroupsUpdateProperties(title: entry.key),
        );
        if (entry.key == 'Unclassified') {
          unclassified = groupId;
        }
      }
      if (unclassified != -1) {
        await moveTabGroups(unclassified, TabGroupsMoveProperties(index: -1));
      }
      await fetchTabs();
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final categoryInfoProvider =
    StateNotifierProvider<CategoryInfoNotifier, AsyncValue<CategoryInfo>>(
        (ref) => CategoryInfoNotifier());
