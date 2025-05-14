import 'dart:convert';
import 'dart:io';

Future<String> convertFileToBase64(File file) async {
  List<int> imageBytes = await file.readAsBytes();
  String fileExtension = file.path.split('.').last.toLowerCase();

  return "data:image/$fileExtension;base64,${base64Encode(imageBytes)}";
}
