import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/session/consent_gate_controller.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/legal_text_sheet.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/consent_review.dart';
import '../domain/privacy_notice.dart';

/// Asks a signed-in resident to accept a Terms of Use or Privacy Notice
/// version published since they last agreed.
///
/// ---
///
/// **It says what changed before it asks.** Each changed text gets a line, a
/// date when the LGU published one, and a way to read it in the same sheet
/// registration uses. A text the LGU has not written yet still opens, and the
/// sheet says so instead of showing a placeholder as if it were the text.
///
/// **Two ways on, and a third only when the server failed.** "I agree" records
/// the missing versions; "Sign out" returns to guest browsing. When recording
/// fails the screen says so plainly — never that it was recorded — and offers
/// to continue without it, because a request that cannot get through must not
/// keep a resident out of their own account.
///
/// The screen does not navigate. It changes the gate; the router moves.
class ConsentUpdateScreen extends StatelessWidget {
  const ConsentUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependencies.of(context);
    final ConsentGateController gate = dependencies.consentGate;
    return ListenableBuilder(
      listenable: gate,
      builder: (BuildContext context, _) {
        final ConsentReview? review = gate.review;
        if (review == null) {
          // Nothing is owed: the guard is already sending the resident on.
          return const Scaffold(backgroundColor: BrandColors.surface);
        }
        return _ConsentUpdateBody(
          review: review,
          recording: gate.isRecording,
          failure: gate.recordFailure,
          onAgree: () => unawaited(gate.agree()),
          onContinue: gate.continueForNow,
          onSignOut: () => unawaited(_signOut(dependencies)),
        );
      },
    );
  }

  static Future<void> _signOut(AppDependencies dependencies) async {
    await dependencies.authRepository.signOut();
    await dependencies.session.signOut();
  }
}

class _ConsentUpdateBody extends StatelessWidget {
  const _ConsentUpdateBody({
    required this.review,
    required this.recording,
    required this.failure,
    required this.onAgree,
    required this.onContinue,
    required this.onSignOut,
  });

  final ConsentReview review;
  final bool recording;
  final AppFailure? failure;
  final VoidCallback onAgree;
  final VoidCallback onContinue;
  final VoidCallback onSignOut;

  bool get _terms => review.missing.contains(ConsentText.termsOfUse);
  bool get _privacy => review.missing.contains(ConsentText.privacyNotice);

  String get _title => switch ((_terms, _privacy)) {
    (true, true) => 'The Terms of Use and the Privacy Notice have changed',
    (true, false) => 'The Terms of Use have changed',
    _ => 'The Privacy Notice has changed',
  };

  String _changedLine(ConsentText text) {
    final DateTime? on = review.updatedOn(text);
    final String when = on == null ? '' : ' on ${ManilaTime.formatDate(on)}';
    return switch (text) {
      ConsentText.termsOfUse => 'The Terms of Use were updated$when.',
      ConsentText.privacyNotice => 'The Privacy Notice was updated$when.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppFailure? failed = failure;
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Scrolls rather than shrinks: this screen must survive 200% text,
            // and a resident cannot go around it while signed in.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: IconTile(
                      icon: TaytayIcons.fileText,
                      fill: BrandColors.chipBlueBg,
                      ink: BrandColors.taytayBlue,
                      size: 52,
                      iconSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      _title,
                      style: s3Type(
                        20,
                        AppTypography.black,
                        BrandColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final ConsentText text in ConsentText.values)
                    if (review.missing.contains(text))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _changedLine(text),
                          style: s3Type(
                            15,
                            FontWeight.w600,
                            BrandColors.textPrimary,
                          ),
                        ),
                      ),
                  const SizedBox(height: 6),
                  Text(
                    'Please read what changed. To keep using your account, '
                    'agree to the updated text. If you do not agree, you can '
                    'sign out and keep using the app as a guest.',
                    style: s3Type(
                      14,
                      FontWeight.w400,
                      BrandColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_terms) ...<Widget>[
                    SecondaryButton(
                      key: const Key('consent-read-terms'),
                      label: 'Read the Terms of Use',
                      onPressed: () => _read(context, ConsentText.termsOfUse),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_privacy) ...<Widget>[
                    SecondaryButton(
                      key: const Key('consent-read-privacy'),
                      label: 'Read the Privacy Notice',
                      onPressed: () =>
                          _read(context, ConsentText.privacyNotice),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (failed != null) ...<Widget>[
                    const SizedBox(height: 6),
                    _RecordFailure(failure: failed),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    key: const Key('consent-agree'),
                    label: recording ? 'Recording your agreement…' : 'I agree',
                    onPressed: recording ? null : onAgree,
                  ),
                  if (failed != null && !recording) ...<Widget>[
                    const SizedBox(height: 10),
                    SecondaryButton(
                      key: const Key('consent-continue'),
                      label: 'Continue for now',
                      onPressed: onContinue,
                    ),
                  ],
                  const SizedBox(height: 6),
                  TextButton(
                    key: const Key('consent-sign-out'),
                    onPressed: recording ? null : onSignOut,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        A11y.minTapTarget,
                        A11y.minTapTarget,
                      ),
                    ),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _read(BuildContext context, ConsentText text) {
    final (
      String title,
      PublishedText published,
      String pending,
    ) = switch (text) {
      ConsentText.termsOfUse => (
        'Terms of Use',
        review.terms,
        termsNotPublishedYet,
      ),
      ConsentText.privacyNotice => (
        'Privacy Notice',
        review.privacyNotice,
        privacyNoticeNotPublishedYet,
      ),
    };
    unawaited(
      showLegalTextSheet(
        context,
        title: title,
        // Never the placeholder: until the LGU publishes, the sheet says so.
        markdown: Future<String?>.value(
          published.isPublished ? published.bodyMarkdown : null,
        ),
        pending: pending,
      ),
    );
  }
}

/// Says the agreement was not recorded, or that it could not be confirmed,
/// and never that it was.
class _RecordFailure extends StatelessWidget {
  const _RecordFailure({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final String what = failure.outcomeUnknown
        ? 'We could not confirm that your agreement was recorded. Agreeing '
              'again is safe: it is recorded only once.'
        : 'Your agreement was not recorded. ${failure.residentMessage}';
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('consent-record-failure'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrandColors.chipRedBg,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              what,
              style: s3Type(
                14,
                FontWeight.w600,
                BrandColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can also continue for now without it. The app will ask '
              'again the next time you return to it.',
              style: s3Type(
                13,
                FontWeight.w400,
                BrandColors.textPrimary,
                height: 1.45,
              ),
            ),
            if (failure.requestId case final String reference)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  'Reference: $reference',
                  style: s3Type(12, FontWeight.w400, BrandColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
