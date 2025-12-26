import 'package:flutter/material.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: progress, exercises, learning history.'),
      ),
    );
  }
}
