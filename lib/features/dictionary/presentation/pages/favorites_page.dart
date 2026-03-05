import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dictionary_providers.dart';
import '../widgets/word_card.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteWordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      /// AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              'المفضلة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 12),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: const Color(0xFFE53935),
            onPressed: () => context.pop(),
          ),
        ],
      ),

      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              break; // نحن في المفضلة
            case 2:
              context.go('/dictionary');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: favoritesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (words) {
              if (words.isEmpty) {
                return const Center(
                  child: Text('لا يوجد كلمات مفضلة'),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: words.length,
                itemBuilder: (context, i) => WordCard(
                  word: words[i],
                  categoryId: '', // غير مستخدم هنا
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
