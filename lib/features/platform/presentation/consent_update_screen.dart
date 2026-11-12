import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/session/consent_gate_controller.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/consent_check_card.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/legal_text_sheet.dart';
import '../../../shared/widgets/surface_cards.dart';
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
/// **Each text is its own act** (D-208). An owed text has its own unticked
/// `ConsentCheckCard`, and "I agree" stays off until every one is ticked. A
/// resident whose only agreement is the older app's single tick for both
/// texts is asked here again, because the server counts that row as neither.
///
/// **Two ways on, and a third only when the server failed.** "I agree" records
/// each missing text with its kind; "Sign out" returns to guest browsing. When recording
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
          return const Scaffold(backgroundColor: BrandColors.white);
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

class _ConsentUpdateBody extends StatefulWidget {
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

  @override
  State<_ConsentUpdateBody> createState() => _ConsentUpdateBodyState();
}

class _ConsentUpdateBodyState extends State<_ConsentUpdateBody> {
  /// The ticks, unticked to start: a consent is something the resident does.
  bool _termsTicked = false;
  bool _privacyTicked = false;

  ConsentReview get review => widget.review;
  bool get recording => widget.recording;
  AppFailure? get failure => widget.failure;

  bool get _terms => review.missing.contains(ConsentText.termsOfUse);
  bool get _privacy => review.missing.contains(ConsentText.privacyNotice);

  bool get _allTicked =>
      (!_terms || _termsTicked) && (!_privacy || _privacyTicked);

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
    // The notice pattern (RegTerms): the wave header carries the title, with
    // no back control, because a resident cannot go around this screen while
    // signed in. The changes and the two ways on follow on the white page.
    return AuthFormPage(
      showBack: false,
      title: _title,
      subtitle: 'Bayan ng Taytay · Rizal',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('consent-agree'),
            label: recording ? 'Recording your agreement…' : 'I agree',
            onPressed: recording || !_allTicked ? null : widget.onAgree,
          ),
          if (failed != null && !recording) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            SecondaryButton(
              key: const Key('consent-continue'),
              label: 'Continue for now',
              onPressed: widget.onContinue,
            ),
          ],
          const SizedBox(height: Spacing.xs),
          TextButton(
            key: const Key('consent-sign-out'),
            onPressed: recording ? null : widget.onSignOut,
            style: TextButton.styleFrom(
              foregroundColor: BrandColors.muted,
              minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
              textStyle: AppTypography.link,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SoftCard(
            filled: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const IconTile.lucide(icon: TaytayIcons.fileText),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final ConsentText text in ConsentText.values)
                            if (review.missing.contains(text))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacing.xs,
                                ),
                                child: Text(
                                  _changedLine(text),
                                  style: AppTypography.listTitle.copyWith(
                                    color: BrandColors.ink,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Please read what changed. To keep using your account, '
                  'tick each text below to agree to it. If you do not agree, '
                  'you can sign out and keep using the app as a guest.',
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.formGap),
          if (_terms) ...<Widget>[
            SecondaryButton(
              key: const Key('consent-read-terms'),
              label: 'Read the Terms of Use',
              onPressed: () => _read(context, ConsentText.termsOfUse),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          if (_privacy) ...<Widget>[
            SecondaryButton(
              key: const Key('consent-read-privacy'),
              label: 'Read the Privacy Notice',
              onPressed: () => _read(context, ConsentText.privacyNotice),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          if (_terms) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            ConsentCheckCard(
              key: const Key('consent-tick-terms'),
              value: _termsTicked,
              onChanged: recording
                  ? null
                  : (bool value) => setState(() => _termsTicked = value),
              label: termsConsentLabel,
            ),
          ],
          if (_privacy) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            ConsentCheckCard(
              key: const Key('consent-tick-privacy'),
              value: _privacyTicked,
              onChanged: recording
                  ? null
                  : (bool value) => setState(() => _privacyTicked = value),
              label: privacyConsentLabel,
            ),
          ],
          if (failed != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            _RecordFailure(failure: failed),
          ],
        ],
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
      child: DecoratedBox(
        key: const Key('consent-record-failure'),
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
                what,
                style: AppTypography.listTitle.copyWith(
                  color: BrandColors.redInk,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'You can also continue for now without it. The app will ask '
                'again the next time you return to it.',
                style: AppTypography.listDetail.copyWith(
                  color: BrandColors.ink,
                  height: 1.45,
                ),
              ),
              if (failure.requestId case final String reference)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: SelectableText(
                    'Reference: $reference',
                    style: AppTypography.small.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
