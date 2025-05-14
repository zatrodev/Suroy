import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImagePickerService {
  ImagePickerService._privateConstructor();

  static final ImagePickerService _instance =
      ImagePickerService._privateConstructor();

  static ImagePickerService get instance => _instance;

  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the device's gallery.
  ///
  /// Returns a [File] object if an image is selected, otherwise returns `null`.
  Future<File?> pickImageFromGallery() async {
    if (kIsWeb) {
      print(
        "Image picking from gallery on web might require different handling.",
      );
      // return null; // Or implement web-specific logic
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // You can specify image quality and maxHeight/maxWidth if needed
        imageQuality: 80,
        maxHeight: 1024,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Captures an image using the device's camera.
  ///
  /// Returns a [File] object if an image is captured, otherwise returns `null`.
  Future<File?> pickImageFromCamera() async {
    if (kIsWeb) {
      print(
        "Image picking from camera is generally not supported on web in the same way.",
      );
      return null;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxHeight: 1024,
        maxWidth: 1024,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }
}
