/// The fee and the processing time, said the way a resident reads them.
///
/// **Money is integer centavos, and stays integer.** `fee_centavos` arrives as
/// an int and is split with `~/` and `%`. A `double` would turn ₱50.10 into
/// 50.099999… somewhere between the wire and the screen; there is no division
/// here that could.
///
/// **The fee is paid at the office.** No online payment was supplied, so no
/// line here mentions paying in the app.
library;

import '../../../core/documents/upload_policy.dart';

/// `₱1,250.00` from 125000. Negative values never come from the server; one
/// that did is shown with a minus sign rather than hidden.
String formatPesos(int centavos) {
  final bool negative = centavos < 0;
  final int absolute = negative ? -centavos : centavos;
  final int pesos = absolute ~/ 100;
  final int cents = absolute % 100;
  final String digits = pesos.toString();
  final StringBuffer grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final String centsText = cents.toString().padLeft(2, '0');
  return '${negative ? '-' : ''}₱$grouped.$centsText';
}

/// The fee line on a document type and on a request.
///
/// `null` is "the office stated no fee", which is not the same as "free": the
/// resident is told it was not stated, not that it costs nothing. Zero is a
/// stated fee of nothing.
String issuanceFeeLine(int? feeCentavos) {
  if (feeCentavos == null) return 'No fee stated';
  if (feeCentavos == 0) return 'No fee';
  return 'Fee: ${formatPesos(feeCentavos)}, paid at the office';
}

/// Which files the office takes, from the server's own `accepts` block, so
/// the sentence and the check that enforces it cannot disagree.
String acceptedFilesLine(UploadPolicy policy) {
  final List<String> kinds = <String>[
    for (final String type in policy.mimeTypes) ?_kindName(type),
  ]..sort();
  final String list = switch (kinds.length) {
    0 => 'a file',
    1 => kinds.first,
    _ => '${kinds.sublist(0, kinds.length - 1).join(', ')} or ${kinds.last}',
  };
  return '$list, up to ${policy.maxMegabytes} MB each';
}

/// The name a resident knows a file type by. A type this build cannot name is
/// left out of the sentence rather than shown as a wire value.
String? _kindName(String mimeType) => switch (mimeType) {
  'application/pdf' => 'PDF',
  'image/jpeg' => 'JPEG',
  'image/png' => 'PNG',
  _ => null,
};

/// Working days from the office's Citizen's Charter. `null` is "not stated";
/// zero is the same day.
String issuanceProcessingLine(int? processingDays) {
  if (processingDays == null) return 'Processing time not stated';
  if (processingDays <= 0) return 'Usually the same working day';
  if (processingDays == 1) return 'About 1 working day';
  return 'About $processingDays working days';
}
