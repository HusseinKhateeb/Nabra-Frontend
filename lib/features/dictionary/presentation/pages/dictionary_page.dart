import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../providers/dictionary_providers.dart';
import '../widgets/category_tabs.dart';
import '../widgets/word_card.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';

class DictionaryPage extends ConsumerWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      /// ✅ AppBar مطابق للصورة
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              'القاموس البصري',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: const Color(0xFFE53935),
            onPressed: () => context.go(AppRoutes.lipReading),
          ),
        ],
      ),

      /// Bottom Navigation
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Always reload dictionary page
              context.go(AppRoutes.dictionary + '?reload=${DateTime.now().millisecondsSinceEpoch}');
              break;
            case 1:
              context.go(AppRoutes.sessions);
              break;
            case 2:
              context.go(AppRoutes.lipReading);
              break;
            case 3:
              context.go(AppRoutes.profile);
              break;
            case 4:
              context.go(AppRoutes.chats);
              break;
          }
        },
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              const SizedBox(height: 12),

              /// 🔍 Search Bar (نفس الصورة)
              /// 🔍 Search + ⭐ Favorites Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    /// Search Bar
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن كلمة',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onChanged: (value) {
                            ref.read(searchQueryProvider.notifier).state =
                                value;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// ⭐ Favorites Button
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.star),
                        color: const Color(0xFFE53935),
                        tooltip: 'المفضلة',
                        onPressed: () {
                          context.go(AppRoutes.favorites);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              /// Categories Tabs
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (cats) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ref.read(selectedCategoryProvider) == null &&
                        cats.isNotEmpty) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          cats.first.id;
                    }
                  });

                  return CategoryTabs(categories: cats);
                },
              ),

              const SizedBox(height: 12),

              /// Words Grid
              Expanded(
                child: selectedCategory == null
                    ? const SizedBox()
                    : ref.watch(wordsProvider(selectedCategory)).when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text(e.toString())),
                          data: (words) {
                            final filtered = words
                                .where((w) => w.text.contains(searchQuery))
                                .toList();

                            if (filtered.isEmpty) {
                              return const Center(child: Text('لا يوجد كلمات'));
                            }

                            return GridView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => WordCard(
                                word: filtered[i],
                                categoryId: selectedCategory,
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
