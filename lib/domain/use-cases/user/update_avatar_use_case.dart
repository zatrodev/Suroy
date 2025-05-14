import 'dart:io';
import 'package:app/data/repositories/user/user_repository.dart';
import 'package:app/data/services/internal/image/image_picker_service.dart';
import 'package:app/utils/convert_to_base64.dart';
import 'package:app/utils/result.dart';
import 'package:image_picker/image_picker.dart';

class UpdateAvatarUseCase {
  final UserRepository _userRepository;
  final ImagePickerService _imagePickerService;

  UpdateAvatarUseCase({
    required UserRepository userRepository,
    required ImagePickerService imagePickerService,
  }) : _userRepository = userRepository,
       _imagePickerService = imagePickerService;

  Future<Result<String>> execute(String userId, ImageSource imageSource) async {
    try {
      File? imageFile;
      if (imageSource == ImageSource.camera) {
        imageFile = await _imagePickerService.pickImageFromCamera();
      } else {
        imageFile = await _imagePickerService.pickImageFromGallery();
      }

      if (imageFile == null) {
        return Result.error(
          Exception("No image selected or an error occurred during picking."),
        );
      }

      String base64Image = await convertFileToBase64(imageFile);

      final result = await _userRepository.updateAvatar(userId, base64Image);

      switch (result) {
        case Ok<String>():
          return Result.ok(result.value);
        case Error<String>():
          return Result.error(result.error);
      }
    } catch (e) {
      return Result.error(Exception("Failed to update profile picture: $e"));
    }
  }
}
