import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordSuccessPage extends StatelessWidget {
  const ResetPasswordSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.red,
                  size: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'تم تغيير كلمة المرور',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تم تغيير كلمة المرور بنجاح، يمكنك تسجيل الدخول مرة أخرى باستخدام كلمة مرور جديدة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => context.go('/login'),
                    child: const Text('تم'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
