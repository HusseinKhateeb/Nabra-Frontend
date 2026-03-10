import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? arabicText;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchArabicText();
  }

  Future<void> fetchArabicText() async {
    try {
      final dio = Dio();
      // TODO: Replace with your actual endpoint
      final response = await dio.get('YOUR_ENDPOINT_HERE');
      // Dio handles UTF-8 automatically
      setState(() {
        arabicText = response.data['rawOutput']?.toString();
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: error != null
            ? Text(error!)
            : arabicText != null
                ? Text(arabicText!)
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
