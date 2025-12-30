import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import 'auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController(); // ✅ أضفناه
  final _password = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }

      if (prev is AsyncLoading && next is AsyncData) {
        context.go(AppRoutes.login);
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔙 Back
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF6E6E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'إنشاء حساب',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'املأ معلوماتك أدناه لإنشاء حساب جديد',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 32),

                  /// Full Name
                  TextFormField(
                    controller: _fullName,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.requiredField,
                  ),

                  const SizedBox(height: 16),

                  /// Username
                  TextFormField(
                    controller: _username,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.requiredField,
                  ),

                  const SizedBox(height: 16),

                  /// Email
                  TextFormField(
                    controller: _email,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.email,
                  ),

                  const SizedBox(height: 16),

                  /// Password
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.requiredField,
                  ),

                  const SizedBox(height: 24),

                  /// Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                      ),
                      onPressed: state is AsyncLoading
                          ? null
                          : () {
                              if (!_formKey.currentState!.validate()) return;

                              ref
                                  .read(authControllerProvider.notifier)
                                  .register(
                                    username: _username.text.trim(),
                                    email: _email.text.trim(),
                                    password: _password.text,
                                    displayName: _fullName.text.trim(),
                                  );
                            },
                      child: state is AsyncLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('إنشاء حساب'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب مسبقاً؟'),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
