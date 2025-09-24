import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from camera
  Future<File?> pickImageFromCamera({int quality = 85}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
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

  // Pick image from gallery
  Future<File?> pickImageFromGallery({int quality = 85}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
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

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({int quality = 85}) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: quality,
      );

      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Pick video from camera
  Future<File?> pickVideoFromCamera({Duration? maxDuration}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration ?? const Duration(minutes: 2),
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking video from camera: $e');
      return null;
    }
  }

  // Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }

  // Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final File? image = await pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from existing photos'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final File? image = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Get file size in human readable format
  String getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Check if file is an image
  bool isImage(File file) {
    final String extension = file.path.toLowerCase();
    return extension.endsWith('.jpg') ||
           extension.endsWith('.jpeg') ||
           extension.endsWith('.png') ||
           extension.endsWith('.gif') ||
           extension.endsWith('.bmp') ||
           extension.endsWith('.webp');
  }

  // Check if file is a video
  bool isVideo(File file) {
    final String extension = file.path.toLowerCase();
    return extension.endsWith('.mp4') ||
           extension.endsWith('.avi') ||
           extension.endsWith('.mov') ||
           extension.endsWith('.wmv') ||
           extension.endsWith('.flv') ||
           extension.endsWith('.webm');
  }
}

class MediaData {
  final File file;
  final String fileName;
  final String fileSize;
  final DateTime timestamp;
  final MediaType type;

  MediaData({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.timestamp,
    required this.type,
  });

  factory MediaData.fromFile(File file) {
    final mediaService = MediaService();
    return MediaData(
      file: file,
      fileName: file.path.split('/').last,
      fileSize: mediaService.getFileSize(file),
      timestamp: DateTime.now(),
      type: mediaService.isImage(file) ? MediaType.image : MediaType.video,
    );
  }

  Map<String, dynamic> toJson() => {
    'filePath': file.path,
    'fileName': fileName,
    'fileSize': fileSize,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
  };
}

enum MediaType { image, video }