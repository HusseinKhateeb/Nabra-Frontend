// ignore: uri_does_not_exist
import 'package:flutter/material.dart';

class VoiceInferResultWidget extends StatelessWidget {
  final String resultText;
  const VoiceInferResultWidget({Key? key, required this.resultText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'النص المستخرج:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            resultText,
            style: TextStyle(fontSize: 20, color: Colors.blueAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}