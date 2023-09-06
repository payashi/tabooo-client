import 'package:flutter/material.dart';
import 'package:tab_organizer/chrome_api.dart';
import 'package:tab_organizer/models/chrome_tab.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tab_organizer/providers/tab_list_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: PopupScreen(),
      ),
    ),
  );
}

class PopupScreen extends HookConsumerWidget {
  const PopupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const Column(
        children: [
          TabListView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Future.delayed(const Duration(seconds: 1));
          await ref.read(tabListProvider.notifier).fetch();
        },
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}

class TabListView extends HookConsumerWidget {
  const TabListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(tabListProvider).when(
          loading: CircularProgressIndicator.new,
          error: (error, _) => Text(error.toString()),
          data: (tabs) {
            return Flexible(
              child: ListView.builder(
                itemCount: tabs.length,
                itemBuilder: (context, idx) => _tile(tabs[idx]),
              ),
            );
          },
        );
  }

  Widget _tile(ChromeTab tab) {
    return ListTile(
      hoverColor: Colors.amber.shade50,
      tileColor: Colors.grey.shade50,
      leading: Image.network(
        tab.favIconUrl,
        width: 32,
        height: 32,
        errorBuilder: (context, object, _) => const Icon(
          Icons.public,
          size: 32,
        ),
      ),
      title: Text(
        tab.title,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        hightlightTab(HighlightOptions(
          tabs: tab.index,
          windowId: tab.windowId,
        ));
      },
    );
  }
}
