/// What the office accepts, as the office says it.
///
/// ## The one number, and where it comes from
///
/// Before TAB 01 this app carried **two** upload ceilings that disagreed:
/// `DocumentCapturePolicy.maxBytes` refused above 10 MB when a file was chosen,
/// and `RequirementApiRepository.maxUploadBytes` refused above 8 MB at send.
/// A 9 MB PDF passed the first, waited through the upload preparation, and was
/// refused by the second — and a PDF is never downscaled, so nothing in between
/// could have saved it. Both numbers were guesses, and the repository's own
/// comment said so.
///
/// The server had published the answer the whole time. `GET me/cases/{case}/requirements`
/// carries an `accepts` block — `{mime_types, max_bytes}` — and nothing read it.
///
/// So this type holds the policy, it arrives from the response, and both
/// enforcement points take it as a parameter. **There is no constant here that
/// a screen could reach for instead**, other than [UploadPolicy.fallback], which says what it
/// is.
///
/// ## Why a fallback exists at all, and why it is the lower number
///
/// A checklist can arrive without `accepts` — an older server, a response
/// shaped by a proxy, a test. Refusing to enforce anything there would send
/// megabytes over a resident's prepaid connection to be refused by the server;
/// so [UploadPolicy.fallback] enforces the **lower** of the two ceilings this replaced. Being
/// conservative when uninformed costs a resident one retry with a smaller file.
/// Being permissive when uninformed costs them the upload *and* the data.
///
/// It is labelled ([UploadPolicy.source]) so that a fallback can never be read later as a
/// measurement. That distinction is the same one `docs/frontend/open-work.md`
/// draws about baselines: a value nobody served is not a value the server chose.
library;

/// Where a policy came from. Never inferred at the point of use.
enum UploadPolicySource {
  /// Decoded from the API's own `accepts` block.
  served,

  /// The API did not say. [UploadPolicy.fallback] was used.
  fallback,
}

/// The size and types this office accepts for one upload.
final class UploadPolicy {
  const UploadPolicy({
    required this.maxBytes,
    required this.mimeTypes,
    required this.source,
  });

  /// The ceiling in bytes, inclusive — a file of exactly this size is accepted.
  final int maxBytes;

  /// The MIME types the server will accept, exactly as it published them.
  final Set<String> mimeTypes;

  final UploadPolicySource source;

  /// Used when the API published no policy. See the class comment.
  ///
  /// **This is the only literal ceiling in `lib/`**, and
  /// `test/core/upload_policy_test.dart` fails if a second one appears.
  static const UploadPolicy fallback = UploadPolicy(
    maxBytes: 8 * 1024 * 1024,
    mimeTypes: <String>{'image/jpeg', 'image/png', 'application/pdf'},
    source: UploadPolicySource.fallback,
  );

  /// Reads the API's `accepts` block, or returns [fallback].
  ///
  /// Unknown fields are ignored rather than rejected (API conventions §1), and a
  /// block that carries neither a usable size nor a usable type list is treated
  /// as absent — a policy assembled from half a response is a policy nobody
  /// published.
  static UploadPolicy decode(Object? accepts) {
    if (accepts is! Map<String, dynamic>) return fallback;

    final Object? bytes = accepts['max_bytes'];
    final Object? types = accepts['mime_types'];

    if (bytes is! int || bytes <= 0) return fallback;
    if (types is! List<dynamic>) return fallback;

    final Set<String> mimeTypes = types.whereType<String>().toSet();
    if (mimeTypes.isEmpty) return fallback;

    return UploadPolicy(
      maxBytes: bytes,
      mimeTypes: mimeTypes,
      source: UploadPolicySource.served,
    );
  }

  /// File extensions to offer the system picker, derived rather than listed.
  ///
  /// A second hand-maintained list of extensions is a third copy of the same
  /// decision, and it is the copy that drifts — a picker offering `.heic`
  /// because somebody added it here while the server still refuses it wastes a
  /// resident's upload rather than their tap.
  List<String> get pickerExtensions {
    const Map<String, List<String>> byType = <String, List<String>>{
      'image/jpeg': <String>['jpg', 'jpeg'],
      'image/png': <String>['png'],
      'application/pdf': <String>['pdf'],
    };

    return <String>[
      for (final String type in mimeTypes) ...?byType[type],
    ]..sort();
  }

  /// The ceiling in whole megabytes, for copy a resident reads.
  ///
  /// Rounded **down**, so the sentence never promises more than the server
  /// accepts. 10,485,760 bytes reads as 10 MB; 10,000,000 also reads as 9 rather
  /// than as a 10 that would be refused.
  int get maxMegabytes => maxBytes ~/ (1024 * 1024);

  @override
  String toString() =>
      'UploadPolicy(${maxMegabytes}MB, ${mimeTypes.length} types, ${source.name})';
}
