import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nabra_frontend/features/welcome/presentation/instructions_page.dart';
import 'package:nabra_frontend/features/auth/presentation/forgot_password_page.dart';
import 'package:nabra_frontend/features/auth/presentation/verify_reset_code_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/reset_success_page.dart';
import '../../features/welcome/presentation/welcome_page.dart';
import '../../features/welcome/presentation/permissions_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/lip_reading/presentation/lip_reading_page.dart';
import '../../features/sessions/presentation/sessions_page.dart';
import '../../features/chat/presentation/chats_list_page.dart';
import '../../features/dictionary/presentation/pages/favorites_page.dart';
import '../../features/dictionary/presentation/pages/dictionary_page.dart';
import '../../features/learning/presentation/learning_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../shared/constants.dart';
import 'app_routes.dart';

const FlutterSecureStorage _routerStorage = FlutterSecureStorage();

bool _isPublicRoute(String path) {
  const Set<String> publicRoutes = <String>{
    AppRoutes.welcome,
    AppRoutes.instructions,
    AppRoutes.permissions,
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.verifyResetCode,
    AppRoutes.resetPassword,
    AppRoutes.resetPasswordSuccess,
  };
  return publicRoutes.contains(path);
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    final String path = state.matchedLocation;
    if (_isPublicRoute(path)) return null;

    final String? token = await _routerStorage.read(key: StorageKeys.accessToken) ??
        await _routerStorage.read(key: 'access_token');

    if (token == null || token.trim().isEmpty) {
      return AppRoutes.login;
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.instructions,
      builder: (context, state) => const InstructionsPage(),
    ),
    GoRoute(
      path: AppRoutes.permissions,
      builder: (context, state) => const PermissionsPage(),
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.lipReading,
      builder: (context, state) => const LipReadingPage(),
    ),
    GoRoute(
      path: AppRoutes.sessions,
      builder: (context, state) => const SessionsPage(),
    ),
    GoRoute(
      path: AppRoutes.chats,
      builder: (context, state) => const ChatsListPage(),
    ),
    GoRoute(
      path: AppRoutes.dictionary,
      builder: (context, state) {
        final reload = state.uri.queryParameters['reload'] ?? '';
        return DictionaryPage(key: ValueKey(reload));
      },
    ),
    GoRoute(
      path: AppRoutes.learning,
      builder: (context, state) => const LearningPage(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => const AdminPage(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.verifyResetCode,
      builder: (context, state) {
        final email = state.extra as String;
        return VerifyResetCodePage(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ResetPasswordPage(
          email: data['email'],
          code: data['code'],
        );
      },
    ),
    GoRoute(
      path: '/reset-success',
      builder: (context, state) => const ResetPasswordSuccessPage(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(child: Text(state.error.toString())),
    );
  },
);
