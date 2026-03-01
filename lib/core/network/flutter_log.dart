import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FlutterLog {
  static File? _logFile;

  static Future<File> _getLogFile() async {
    if (_logFile != null) return _logFile!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/flutter_important.log');
    _logFile = file;
    return file;
  }

  static Future<void> write(String message) async {
    final file = await _getLogFile();
    await file.writeAsString(message + '\n', mode: FileMode.append);
  }

  static Future<void> reset() async {
    final file = await _getLogFile();
    await file.writeAsString('');
  }

  static Future<List<String>> readAll() async {
    final file = await _getLogFile();
    if (!await file.exists()) return [];
    return await file.readAsLines();
  }
}
