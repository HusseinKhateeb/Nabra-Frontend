import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dictionary_providers.dart';
import '../widgets/category_tabs.dart';
import '../widgets/word_card.dart';

class DictionaryPage extends ConsumerWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("القاموس البصري"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// 🧩 Categories Tabs
          categoriesAsync.when(
            data: (cats) {
              // ✅ تثبيت أول فئة بعد انتهاء build (حل آمن)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ref.read(selectedCategoryProvider) == null &&
                    cats.isNotEmpty) {
                  ref.read(selectedCategoryProvider.notifier).state =
                      cats.first.id;
                }
              });

              final selected =
                  selectedCategory ?? (cats.isNotEmpty ? cats.first.id : '');

              return CategoryTabs(
                categories: cats,
                selectedId: selected,
                onSelect: (id) {
                  ref.read(selectedCategoryProvider.notifier).state = id;
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// 📦 Words Grid
          Expanded(
            child: selectedCategory == null
                ? const SizedBox()
                : ref.watch(wordsProvider(selectedCategory)).when(
                      data: (words) {
                        final filtered = words
                            .where((w) => w.text.contains(searchQuery))
                            .toList();

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => WordCard(
                            word: filtered[i],
                            categoryId: selectedCategory,
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          e.toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
