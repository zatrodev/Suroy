import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

Future<String> convertFileToBase64(File file) async {
  List<int> imageBytes = await file.readAsBytes();
  String fileExtension = file.path.split('.').last.toLowerCase();

  return "data:image/$fileExtension;base64,${base64Encode(imageBytes)}";
}

Uint8List? convertBase64ToImage(String? base64String) {
  if (base64String == null) return null;

  try {
    String S = base64String;
    if (S.startsWith('data:')) {
      S = S.substring(S.indexOf(',') + 1);
    }
    return base64Url.decode(S);
  } catch (e) {
    print('Error decoding base64 image: $e');
    return null;
  }
}
