Future<void> saveJsonFile(
  String content,
  String fileName, {
  required void Function(String path) onSuccess,
  required void Function(Object error) onError,
}) async {
  throw UnsupportedError('Cannot save file without dart:io or dart:html');
}
