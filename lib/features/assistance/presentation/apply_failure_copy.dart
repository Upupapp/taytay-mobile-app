import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../l10n/app_localizations.dart';

/// What a failed send is said as, in her language (D-226).
///
/// **A failed send says plainly that nothing was sent** (D-087), except when
/// the answer never came: then it is "not confirmed", because the office may
/// have it, and sending again under the same key cannot file twice. The
/// server's own `message` is never shown (Article 5.5).
({String title, String body}) applyFailureCopy(
  AppStrings s,
  AppFailure failure, {
  bool documents = false,
}) {
  return switch (failure) {
    _ when failure.outcomeUnknown => (
      title: s.applyUnconfirmedTitle,
      body: documents ? s.addDocsUnconfirmedBody : s.applyUnconfirmedBody,
    ),
    ForbiddenFailure(requiresVerification: true) => (
      title: s.applyNotVerifiedTitle,
      body: s.applyNotVerifiedBody,
    ),
    ForbiddenFailure() => (
      title: s.applyNotAllowedTitle,
      body: s.applyNotAllowedBody,
    ),
    // Past the guard above, the connection failed before anything left.
    NetworkFailure() ||
    TimeoutFailure() => (title: s.applyOfflineTitle, body: s.applyOfflineBody),
    ValidationFailure() when !documents && _closed(failure) => (
      title: s.applyNotOfferedTitle,
      body: s.applyClosedBody,
    ),
    ValidationFailure() => (title: s.applyCheckTitle, body: s.applyCheckBody),
    UnacceptableUploadFailure() => (
      title: s.applyFileTitle,
      body: s.applyFileBody,
    ),
    RateLimitedFailure() => (title: s.applyRateTitle, body: s.applyRateBody),
    ConflictFailure() when documents => (
      title: s.addDocsMovedTitle,
      body: s.addDocsMovedBody,
    ),
    // Not linked, or her record retired: said on its own page, not here.
    ConflictFailure() => (
      title: s.applyNotLinkedTitle,
      body: s.applyNotLinkedBody,
    ),
    NotFoundFailure() when documents => (
      title: s.addDocsMovedTitle,
      body: s.addDocsMovedBody,
    ),
    UnauthenticatedFailure() => (
      title: s.applySessionTitle,
      body: s.applySessionBody,
    ),
    NotFoundFailure() ||
    ServerFailure() ||
    ContractFailure() ||
    UnexpectedFailure() ||
    CodeExchangeFailure() => (
      title: s.applyServerTitle,
      body: s.applyServerBody,
    ),
  };
}

bool _closed(ValidationFailure failure) =>
    failure.fieldErrors.containsKey('service_slug') ||
    failure.fieldErrors.containsKey('program_id');

/// The failure, said on the step she is on: a title, the sentence, and the
/// reference to quote at the support desk when the server gave one.
class SendFailureNotice extends StatelessWidget {
  const SendFailureNotice({
    required this.failure,
    this.documents = false,
    super.key,
  });

  final AppFailure failure;
  final bool documents;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final ({String title, String body}) copy = applyFailureCopy(
      s,
      failure,
      documents: documents,
    );
    return Semantics(
      liveRegion: true,
      child: Padding(
        key: const Key('apply-send-failure'),
        padding: const EdgeInsets.only(bottom: Spacing.formGap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.red50,
            borderRadius: BorderRadius.circular(Radii.note),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.section),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  copy.title,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.redInk,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  copy.body,
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.ink,
                    height: 1.5,
                  ),
                ),
                if (failure.requestId case final String reference)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: SelectableText(
                      s.applyFailureReference(reference),
                      style: AppTypography.small.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
