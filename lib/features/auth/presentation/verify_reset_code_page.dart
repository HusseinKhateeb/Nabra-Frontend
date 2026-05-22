import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_api.dart';
import 'auth_providers.dart';

class VerifyResetCodePage extends ConsumerStatefulWidget {
  final String email;

  const VerifyResetCodePage({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyResetCodePage> createState() =>
      _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends ConsumerState<VerifyResetCodePage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _collectCode() {
    // طالما الـ Row صار LTR، هذا التجميع صار صحيح 100%
    return _controllers.map((c) => c.text.trim()).join();
  }

  Future<void> _submit() async {
    final code = _collectCode();

    if (code.length != 6 || code.contains(RegExp(r'[^0-9]'))) {
      _showError('رمز التحقق غير مكتمل');
      return;
    }

    setState(() => _loading = true);

    try {
      final AuthApi authApi = ref.read(authApiProvider);

      await authApi.verifyResetCode(
        email: widget.email.trim(),
        code: code,
      );

      // ✅ نجاح → روح لصفحة reset-password (بدك تكون عاملها Route)
      context.go(
        '/reset-password',
        extra: {
          'email': widget.email.trim(),
          'code': code,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      _showError(data?.toString() ?? 'فشل الاتصال بالسيرفر');
    } catch (_) {
      _showError('حدث خطأ غير متوقع');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F6F8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.red),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'التحقق من البريد الإلكتروني',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // ✅ أهم تعديل: Row LTR حتى ما ينعكس ترتيب الأرقام
              Row(
                textDirection: TextDirection.ltr, // ✅ هذا اللي كان ناقص!
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    height: 52,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty) {
                          if (i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              const Text(
                'لم يصلك الرمز؟ أعد الإرسال',
                style: TextStyle(color: Colors.red),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'متابعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
