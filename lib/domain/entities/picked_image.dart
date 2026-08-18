/// A photo chosen by the user (camera or gallery), decoupled from both the picker
/// and the HTTP layer: just the bytes and a filename for the multipart upload.
class PickedImage {
  final List<int> bytes;
  final String filename;

  const PickedImage({required this.bytes, required this.filename});

  /// True when the chosen file is a PDF. Documents may be a photo or a PDF;
  /// vehicle photos are always images. Drives the preview (thumbnail vs icon).
  bool get isPdf => filename.toLowerCase().endsWith('.pdf');
}

