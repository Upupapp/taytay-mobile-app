import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';

// Moved from `test/features/requirements_test.dart` when the requirements page
// it also covered was removed (D-225). `DocumentCapturePolicy` stays: the
// document request, sector and verification uploads all check a file with it.

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real Taytay resident, document number or filename.

/// Real leading bytes, so the signature check in `DocumentCapturePolicy` is
/// exercised rather than bypassed.
Uint8List jpegBytes([int padding = 64]) => Uint8List.fromList(<int>[
  0xFF,
  0xD8,
  0xFF,
  ...List<int>.filled(padding, 0),
]);

Uint8List pngBytes([int padding = 64]) => Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  ...List<int>.filled(padding, 0),
]);

Uint8List pdfBytes([int padding = 64]) => Uint8List.fromList(<int>[
  0x25,
  0x50,
  0x44,
  0x46,
  ...List<int>.filled(padding, 0),
]);

CapturedDocument captured({
  Uint8List? bytes,
  String mimeType = 'image/jpeg',
  String fileName = 'document.jpg',
  DocumentSource source = DocumentSource.camera,
}) => CapturedDocument(
  bytes: bytes ?? jpegBytes(),
  fileName: fileName,
  mimeType: mimeType,
  source: source,
);

/// A served policy by default, so the tests exercise the path a resident takes
/// rather than the fallback.
const UploadPolicy servedPolicy = UploadPolicy(
  maxBytes: 10 * 1024 * 1024,
  mimeTypes: <String>{'image/jpeg', 'image/png', 'application/pdf'},
  source: UploadPolicySource.served,
);

void main() {
  group('what may be uploaded', () {
    test('an empty file is refused', () {
      expect(
        DocumentCapturePolicy.inspect(
          captured(bytes: Uint8List(0)),
          servedPolicy,
        ),
        DocumentRejection.empty,
      );
    });

    test('a file over the ceiling is refused', () {
      final huge = Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        0xFF,
        ...List<int>.filled(servedPolicy.maxBytes, 0),
      ]);

      expect(
        DocumentCapturePolicy.inspect(captured(bytes: huge), servedPolicy),
        DocumentRejection.tooLarge,
      );
    });

    test('a type the office does not accept is refused', () {
      expect(
        DocumentCapturePolicy.inspect(
          captured(mimeType: 'application/zip'),
          servedPolicy,
        ),
        DocumentRejection.unsupportedType,
      );
    });

    test('a declared type is checked against the actual bytes', () {
      // A ZIP renamed to .jpg: the declared type is acceptable, the bytes are
      // not. Caught on the device so the resident is told something useful now,
      // rather than after a round trip.
      final spoofed = Uint8List.fromList(<int>[
        0x50,
        0x4B,
        0x03,
        0x04,
        ...List<int>.filled(32, 0),
      ]);

      expect(
        DocumentCapturePolicy.inspect(captured(bytes: spoofed), servedPolicy),
        DocumentRejection.contentsDoNotMatchType,
      );
    });

    test('JPEG, PNG and PDF are all accepted', () {
      expect(DocumentCapturePolicy.inspect(captured(), servedPolicy), isNull);
      expect(
        DocumentCapturePolicy.inspect(
          captured(bytes: pngBytes(), mimeType: 'image/png'),
          servedPolicy,
        ),
        isNull,
      );
      expect(
        DocumentCapturePolicy.inspect(
          captured(bytes: pdfBytes(), mimeType: 'application/pdf'),
          servedPolicy,
        ),
        isNull,
      );
    });

    test(
      'the two checks agree — the 9 MB PDF that used to pass one and fail the other',
      () {
        // The TAB 01 defect, as a regression. DocumentCapturePolicy accepted up
        // to 10 MB and RequirementApiRepository refused above 8, so a 9 MB PDF
        // passed the check made when the file was chosen and died at the one
        // made when it was sent — after the resident had waited through the
        // preparation, and with no downscaling possible because a PDF is never
        // re-encoded.
        //
        // Both now read the same policy, so whichever answer is right, it is the
        // same answer at both points.
        final nineMegabytes = Uint8List.fromList(<int>[
          0x25,
          0x50,
          0x44,
          0x46,
          ...List<int>.filled(9 * 1024 * 1024, 0),
        ]);

        final document = captured(
          bytes: nineMegabytes,
          mimeType: 'application/pdf',
        );

        // Served 10 MB: accepted, and it stays accepted all the way to the wire.
        expect(
          DocumentCapturePolicy.inspect(document, servedPolicy),
          isNull,
          reason: 'the server accepts 10 MB, so 9 MB is fine',
        );
        expect(document.sizeBytes, lessThanOrEqualTo(servedPolicy.maxBytes));

        // Fallback 8 MB: refused, and refused at the moment it is chosen rather
        // than after the wait.
        expect(
          DocumentCapturePolicy.inspect(document, UploadPolicy.fallback),
          DocumentRejection.tooLarge,
        );
        expect(
          document.sizeBytes,
          greaterThan(UploadPolicy.fallback.maxBytes),
          reason: 'and the send-side check would agree, being the same number',
        );
      },
    );

    test('a PDF is never re-encoded, an image may be', () {
      expect(DocumentCapturePolicy.mayCompress('application/pdf'), isFalse);
      expect(DocumentCapturePolicy.mayCompress('image/jpeg'), isTrue);
    });

    test('the readability floor stays above 150 DPI on A4 — acceptance 1', () {
      // A4's long edge is 8.27in, so 150 DPI needs ~1240px and 200 DPI ~1654px.
      // The floor must sit inside that band or small print stops being legible
      // after the platform re-encodes.
      expect(DocumentCapturePolicy.minLongEdge, greaterThanOrEqualTo(1240));
      expect(DocumentCapturePolicy.imageQuality, greaterThanOrEqualTo(80));
    });
  });
}
