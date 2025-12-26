import 'package:flutter/material.dart';

class DictionaryPage extends StatelessWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visual Dictionary')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('TODO: GET /dictionary, search, categories, favorites.'),
      ),
    );
  }
}
