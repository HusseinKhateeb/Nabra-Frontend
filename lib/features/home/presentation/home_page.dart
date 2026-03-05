import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nabra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavTile(
            title: 'Lip Reading Session',
            subtitle: 'Start/stop session and send video to backend',
            onTap: () => context.push(AppRoutes.lipReading),
          ),
          _NavTile(
            title: 'Sessions History',
            subtitle: 'Browse past sessions and filters',
            onTap: () => context.push(AppRoutes.sessions),
          ),
          _NavTile(
            title: 'Chat',
            subtitle: 'Send/receive messages (text / voice transcript)',
            onTap: () => context.push(AppRoutes.chats),
          ),
          _NavTile(
            title: 'Visual Dictionary',
            subtitle: 'Browse words + categories + favorites',
            onTap: () => context.push(AppRoutes.dictionary),
          ),
          _NavTile(
            title: 'Learning',
            subtitle: 'Progress + exercises',
            onTap: () => context.push(AppRoutes.learning),
          ),
          _NavTile(
            title: 'Admin',
            subtitle: 'Reports + moderation (ROLE_ADMIN)',
            onTap: () => context.push(AppRoutes.admin),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
