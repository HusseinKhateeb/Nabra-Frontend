import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/token_storage.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/constants.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final TokenStorage storage = ref.read(tokenStorageProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final token = await storage.readAccessToken();
    final onboardingDone =
        await secureStorage.read(key: StorageKeys.onboardingCompleted);

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      context.go(AppRoutes.lipReading);
    } else if (onboardingDone == 'true') {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
