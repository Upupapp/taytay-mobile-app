/// What the Apply wizard checks before anything leaves the phone (D-226).
///
/// The server checks the same things and its answer is the one that counts
/// (`POST /me/assistance-applications`, backend `6794f8d`, ADR 0004 decision
/// 2). These are here so a resident learns what is missing on the step she is
/// on, instead of after an upload over a prepaid connection.
///
/// **Money is integer centavos, and stays integer.** A typed amount is read
/// digit by digit into centavos; nothing here is ever a `double`, so ₱1,250.10
/// cannot become 125009.99999 on the way to the office.
library;

import '../../../core/documents/document_capture.dart';
import '../../tulong/domain/social_service.dart';

/// The server trims, then counts: 12 to 2000 characters.
const int applicationPurposeMin = 12;
const int applicationPurposeMax = 2000;

/// `requested_amount_centavos` is at most ten digits on the wire
/// (`^[0-9]{1,10}$`): ₱99,999,999.99.
const int applicationAmountMaxCentavos = 9999999999;

/// Why a purpose cannot be sent.
enum ApplicationPurposeProblem { empty, tooShort, tooLong }

ApplicationPurposeProblem? checkApplicationPurpose(String text) {
  final int length = text.trim().length;
  if (length == 0) return ApplicationPurposeProblem.empty;
  if (length < applicationPurposeMin) return ApplicationPurposeProblem.tooShort;
  if (length > applicationPurposeMax) return ApplicationPurposeProblem.tooLong;
  return null;
}

/// Why a typed amount cannot be sent.
enum ApplicationAmountProblem { unreadable, zero, tooLarge }

/// A typed peso amount, read into whole centavos.
///
/// Blank is "no amount", which is allowed: the amount is optional, and the
/// office decides what it gives. Accepts `1500`, `1,500`, `1500.5`,
/// `₱1,500.50` and `PHP 1500`; refuses a minus sign, more than two decimal
/// places, letters, and commas that do not group thousands.
sealed class ApplicationAmount {
  const ApplicationAmount();

  static ApplicationAmount parse(String typed) {
    String text = typed.trim();
    if (text.isEmpty) return const AmountNotGiven();
    text = text
        .replaceFirst(RegExp(r'^(₱|PHP|Php|php|P)\s*'), '')
        .replaceAll(' ', '');
    final RegExpMatch? match = _amount.firstMatch(text);
    if (match == null) {
      return const AmountRefused(ApplicationAmountProblem.unreadable);
    }
    final String whole = (match.group(1) ?? '').replaceAll(',', '');
    final String fraction = (match.group(2) ?? '').padRight(2, '0');
    // Eleven digits of pesos already exceed the wire's ten digits of
    // centavos; refusing here keeps the arithmetic inside an int's range.
    if (whole.length > 11) {
      return const AmountRefused(ApplicationAmountProblem.tooLarge);
    }
    final int? pesos = int.tryParse(whole);
    final int? cents = int.tryParse(fraction);
    if (pesos == null || cents == null) {
      return const AmountRefused(ApplicationAmountProblem.unreadable);
    }
    final int centavos = pesos * 100 + cents;
    if (centavos == 0) {
      return const AmountRefused(ApplicationAmountProblem.zero);
    }
    if (centavos > applicationAmountMaxCentavos) {
      return const AmountRefused(ApplicationAmountProblem.tooLarge);
    }
    return AmountGiven(centavos);
  }

  /// Whole pesos with commas grouping thousands, or plain digits; then an
  /// optional point and one or two digits.
  static final RegExp _amount = RegExp(
    r'^((?:\d{1,3}(?:,\d{3})+)|\d+)(?:\.(\d{1,2}))?$',
  );
}

/// Nothing typed. Sent as no `requested_amount_centavos` at all.
final class AmountNotGiven extends ApplicationAmount {
  const AmountNotGiven();
}

/// A readable amount, in integer centavos.
final class AmountGiven extends ApplicationAmount {
  const AmountGiven(this.centavos);

  final int centavos;
}

/// Typed, and not an amount that can be sent.
final class AmountRefused extends ApplicationAmount {
  const AmountRefused(this.problem);

  final ApplicationAmountProblem problem;
}

/// The required documents that have no file yet, in the programme's order.
///
/// Only `required` ones: an optional or conditional document is the
/// resident's to judge, and the office says when one was needed after all.
List<ApplicationRequirement> missingRequiredDocuments(
  List<ApplicationRequirement> requirements,
  Map<String, CapturedDocument> chosen,
) => <ApplicationRequirement>[
  for (final ApplicationRequirement requirement in requirements)
    if (requirement.required && !chosen.containsKey(requirement.code))
      requirement,
];
