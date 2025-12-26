import 'package:flutter/material.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions History')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: call GET /sessions/history with filters and show list.'),
      ),
    );
  }
}
