import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromCamera({int imageQuality = 50}) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
    if (photo == null) return null;
    return File(photo.path);
  }
}