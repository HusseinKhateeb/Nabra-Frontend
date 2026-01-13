import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/lip_reading/presentation/lip_reading_page.dart';
import '../../features/sessions/presentation/sessions_page.dart';
<<<<<<< HEAD
import '../../features/chat/presentation/chat_page.dart';
import '../../features/dictionary/presentation/dictionary_page.dart';
=======
import '../../features/chat/presentation/chats_list_page.dart';
import '../../features/dictionary/presentation/pages/favorites_page.dart';
import '../../features/dictionary/presentation/pages/dictionary_page.dart';
>>>>>>> 8fe1ec9... feat : dictionary
import '../../features/learning/presentation/learning_page.dart';
import '../../features/admin/presentation/admin_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
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
<<<<<<< HEAD
=======
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
>>>>>>> 72f1348... edit on dicitonary
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
