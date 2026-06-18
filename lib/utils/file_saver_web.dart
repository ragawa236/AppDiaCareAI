import 'dart:html' as html;
import 'dart:convert';

Future<void> saveJsonFile(
  String content,
  String fileName, {
  required void Function(String path) onSuccess,
  required void Function(Object error) onError,
}) async {
  try {
    // Save to localStorage
    html.window.localStorage['exported_user_data'] = content;

    // Trigger download in browser
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    onSuccess('Unduhan Browser & window.localStorage');
  } catch (e) {
    onError(e);
  }
}
