import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveJsonFile(
  String content,
  String fileName, {
  required void Function(String path) onSuccess,
  required void Function(Object error) onError,
}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    onSuccess(file.path);
  } catch (e) {
    onError(e);
  }
}
