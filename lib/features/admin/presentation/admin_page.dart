import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: moderation + reports (ROLE_ADMIN).'),
      ),
    );
  }
}
