import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/lip_reading/presentation/lip_reading_page.dart';
import '../../features/sessions/presentation/sessions_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/dictionary/presentation/dictionary_page.dart';
import '../../features/learning/presentation/learning_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
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
      path: AppRoutes.chat,
      builder: (context, state) => const ChatPage(),
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
      path: AppRoutes.admin,
      builder: (context, state) => const AdminPage(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(child: Text(state.error.toString())),
    );
  },
);
