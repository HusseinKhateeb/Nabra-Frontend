import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/main_bottom_nav_bar.dart';
import 'providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: const Color(0xFFE53935),
            onPressed: () => context.go(AppRoutes.lipReading),
          ),
        ],
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'الملف الشخصي',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('خطأ: ${error.toString()}'),
        ),
        data: (profile) {
          // Format join date
          final joinDate = DateTime.parse(profile.joinDate);
          final arabicMonth = _getArabicMonth(joinDate.month);
          final formattedDate = '${arabicMonth} ${joinDate.year}';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User name
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      // Join date
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Edit and Save buttons
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Edit profile action
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'تعديل',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Save profile action
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'حفظ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Personal Information Section
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'المعلومات الشخصية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),

                      // First Name Field
                      _buildTextField(
                        label: 'الاسم الاول',
                        value: profile.displayName.split(' ').first,
                      ),
                      const SizedBox(height: 12),

                      // Last Name / Father Name Field
                      _buildTextField(
                        label: 'اسم الاب',
                        value: profile.displayName.split(' ').length > 1
                            ? profile.displayName.split(' ').skip(1).join(' ')
                            : '',
                      ),
                      const SizedBox(height: 12),

                      // Email Field
                      _buildTextField(
                        label: 'البريد الالكتروني',
                        value: profile.email,
                      ),
                      const SizedBox(height: 12),

                      // Phone Number Field
                      _buildTextField(
                        label: 'رقم الهاتف',
                        value: profile.phoneNumber ?? '',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Section
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'الاحصائيات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            count: profile.statistics.transfers.toString(),
                            label: 'التحويلات',
                          ),
                          _buildStatItem(
                            count: profile.statistics.hoursOfUse
                                .toStringAsFixed(1),
                            label: 'ساعات الاستخدام',
                          ),
                          _buildStatItem(
                            count:
                                profile.statistics.accuracy.toStringAsFixed(0),
                            label: 'الدقة',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Logout section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(tokenStorageProvider).clear();
                        if (!context.mounted) return;
                        context.go(AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.dictionary);
              break;
            case 1:
              context.go(AppRoutes.favorites);
              break;
            case 2:
              context.go(AppRoutes.lipReading);
              break;
            case 3:
              // Already on profile
              break;
            case 4:
              context.go(AppRoutes.chats);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
