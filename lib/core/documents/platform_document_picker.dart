import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';

import 'document_capture.dart';

/// The real picker: the system camera, the system photo picker, and the system
/// document picker.
///
/// ---
///
/// **Thin by design.** Everything that can be decided without a platform channel
/// — what may be uploaded, how far a photo may be compressed, whether the bytes
/// match their declared type — lives in `DocumentCapturePolicy`, where it is
/// unit-tested. This class only translates between two plugin APIs and
/// [CapturedDocument], which is the part that genuinely cannot run in a widget
/// test.
///
/// **Compression happens in the platform, at a floor this app sets.**
/// `image_picker` re-encodes natively, which is what makes it affordable on the
/// mid-range phones most residents carry, and the floor
/// (`DocumentCapturePolicy.minLongEdge`, `imageQuality`) keeps small print
/// legible. A PDF goes through `file_selector` and is never re-encoded.
///
/// **The file is read once, into memory, and the path is dropped.** See
/// [CapturedDocument] for why a path is not kept.
class PlatformDocumentPicker implements DocumentPicker {
  PlatformDocumentPicker({ImagePicker? imagePicker})
    : _images = imagePicker ?? ImagePicker();

  final ImagePicker _images;

  @override
  bool supports(DocumentSource source) {
    // The desktop platforms this project may be run on for development have no
    // camera the plugin can reach; the file picker works everywhere.
    if (source == DocumentSource.file) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<CapturedDocument?> pick(DocumentSource source) async {
    return switch (source) {
      DocumentSource.camera => _pickImage(ImageSource.camera, source),
      DocumentSource.gallery => _pickImage(ImageSource.gallery, source),
      DocumentSource.file => _pickFile(),
    };
  }

  Future<CapturedDocument?> _pickImage(
    ImageSource imageSource,
    DocumentSource source,
  ) async {
    final picked = await _images.pickImage(
      source: imageSource,
      // Both edges take the floor, so a portrait document is constrained by its
      // long edge whichever way round it was taken.
      maxWidth: DocumentCapturePolicy.minLongEdge.toDouble(),
      maxHeight: DocumentCapturePolicy.minLongEdge.toDouble(),
      imageQuality: DocumentCapturePolicy.imageQuality,
      requestFullMetadata: false,
    );
    // `null` means the resident backed out. Not an error.
    if (picked == null) return null;

    return CapturedDocument(
      bytes: await picked.readAsBytes(),
      fileName: picked.name,
      // The plugin reports a type on some platforms and not others; fall back to
      // JPEG, which is what its re-encoder produces. The policy re-checks the
      // actual bytes either way, so a wrong guess is caught rather than trusted.
      mimeType: picked.mimeType ?? 'image/jpeg',
      source: source,
    );
  }

  Future<CapturedDocument?> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(
          label: 'Documents',
          extensions: DocumentCapturePolicy.acceptedExtensions,
          mimeTypes: <String>['image/jpeg', 'image/png', 'application/pdf'],
        ),
      ],
    );
    if (file == null) return null;

    return CapturedDocument(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      mimeType: file.mimeType ?? _typeFromExtension(file.name),
      source: DocumentSource.file,
    );
  }

  /// Last resort when the OS reports no type. The signature check in
  /// `DocumentCapturePolicy.inspect` is what actually decides.
  static String _typeFromExtension(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}
