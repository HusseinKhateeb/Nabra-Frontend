import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/constants.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({Key? key}) : super(key: key);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),

                /// Title
                const Text(
                  'الأذونات المطلوبة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 20),

                /// Description
                const Text(
                  'نحتاج إلى بعض الأذونات لتشغيل التطبيق بشكل صحيح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                
                const SizedBox(height: 12),

                const Text(
                  'نقوم بدمج صورة الشفاه (الفيديو) مع الصوت لزيادة دقة فهم الكلام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 40),

                /// Camera Permission
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'الكاميرا',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'نحتاج الوصول إلى الكاميرا لتحليل حركات شفاهك ودمجها مع الصوت لفهم الكلام بدقة أكبر',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Color(0xFFD32F2F),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// Microphone Permission
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'الميكروفون',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'نحتاج الوصول إلى الميكروفون لتسجيل الصوت ودمجه مع قراءة الشفاه',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Color(0xFFD32F2F),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// Privacy Text
                Text(
                  'نحن نحترم خصوصيتك ولا نقوم بتخزين أي فيديوهات أو تسجيلات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 60),

                /// Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _storage.write(
                        key: StorageKeys.onboardingCompleted,
                        value: 'true',
                      );
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'المتابعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Progress Indicator
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
