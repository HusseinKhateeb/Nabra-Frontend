import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 20),
                // Title
                Text(
                  'أهلاً بك في نبرة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 60),
                // Framed App logo
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFEEEEEE), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(18),
                    child: ClipOval(
                      child: Image.asset(
                        'lib/assets/images/Nabra-Logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 60),
                // Description Text
                Text(
                  'نُدمج فيديو الشفاه مع الصوت للحصول على فهم أدق للكلام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.7,
                  ),
                ),
                SizedBox(height: 80),
                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.instructions);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'ابدأ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Progress Indicator
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
