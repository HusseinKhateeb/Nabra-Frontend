import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

import '../../features/dictionary/presentation/dictionary_page.dart';
import '../../features/learning/presentation/learning_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
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
      builder: (context, state) => const DictionaryPage(),
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
      path: AppRoutes.admin,
      builder: (context, state) => const AdminPage(),
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
