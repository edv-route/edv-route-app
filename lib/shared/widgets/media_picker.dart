import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../domain/entities/picked_image.dart';

final ImagePicker _picker = ImagePicker();

/// Upload cap enforced by the backend (documents + vehicle photos + receipt).
/// Checking it here rejects the file before it can create a registration whose
/// later upload would fail — no orphaned record, clear feedback instead.
const int _maxFileBytes = 10 * 1024 * 1024; // 10 MB
const String _oversizeMessage = 'El archivo supera el límite de 10 MB.';

bool _isOversize(PickedImage img) => img.bytes.length > _maxFileBytes;

/// Camera/gallery sheet for PHOTOS (images only). Returns the chosen photo, or
/// null if cancelled or over the 10 MB cap (a snackbar explains the latter).
Future<PickedImage?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final img = await _photoFrom(source);
  if (img == null || !_isOversize(img)) return img;
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(_oversizeMessage)));
  }
  return null;
}

/// Capture sheet for DOCUMENTS: a photo (camera) OR a file (image or PDF).
/// Returns the chosen file, or null if cancelled or over the 10 MB cap.
Future<PickedImage?> pickDocument(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.attach_file, color: AppColors.primary),
            title: const Text('Elegir archivo (imagen o PDF)'),
            onTap: () => Navigator.pop(ctx, 'file'),
          ),
        ],
      ),
    ),
  );
  if (choice == null) return null;
  final PickedImage? img;
  if (choice == 'camera') {
    img = await _photoFrom(ImageSource.camera);
  } else {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.first;
    if (picked.bytes == null) return null;
    img = PickedImage(bytes: picked.bytes!, filename: picked.name);
  }
  if (img == null || !_isOversize(img)) return img;
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(_oversizeMessage)));
  }
  return null;
}

Future<PickedImage?> _photoFrom(ImageSource source) async {
  final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return PickedImage(bytes: bytes, filename: file.name);
}
