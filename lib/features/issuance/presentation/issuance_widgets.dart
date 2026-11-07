import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_status.dart';

/// The frame every document-request screen sits in: the navy municipal header
/// with its back control, a scrolling body, and an optional footer action.
class IssuanceScaffold extends StatelessWidget {
  const IssuanceScaffold({
    required this.title,
    required this.body,
    this.footer,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final Widget? bottom = footer;
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Column(
        children: <Widget>[
          MunicipalHeader(title: title, subtitle: 'Bayan ng Taytay · Rizal'),
          Expanded(child: body),
          if (bottom != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: bottom,
              ),
            ),
        ],
      ),
    );
  }
}

/// The colour a status chip carries. The words on it are always the label, so
/// colour is never the only signal.
StatusTone issuanceStatusTone(IssuanceStatus? status) => switch (status) {
  IssuanceStatus.submitted || IssuanceStatus.underReview => StatusTone.blue,
  IssuanceStatus.needsInfo => StatusTone.amber,
  IssuanceStatus.approved => StatusTone.green,
  IssuanceStatus.readyForPickup => StatusTone.gold,
  IssuanceStatus.released => StatusTone.green,
  IssuanceStatus.rejected => StatusTone.red,
  IssuanceStatus.cancelled || null => StatusTone.grey,
};

class IssuanceStatusChip extends StatelessWidget {
  const IssuanceStatusChip({required this.status, super.key});

  final IssuanceStatus? status;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: issuanceStatusLabel(status),
    tone: issuanceStatusTone(status),
  );
}

/// `05 Nov 2026`, in Manila time, or a dash when the server sent none.
String issuanceDate(DateTime? instant) =>
    instant == null ? '—' : ManilaTime.formatDate(instant);

/// A card with a heading, in the verification pages' card style.
class IssuanceCard extends StatelessWidget {
  const IssuanceCard({required this.child, this.title, super.key});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? heading = title;
    return Padding(
      padding: const EdgeInsets.only(bottom: s3CardGap),
      child: S3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (heading != null) ...<Widget>[
              Semantics(
                header: true,
                child: Text(
                  heading,
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Body copy at the card's size. Wraps, and grows with the text scale.
class IssuanceText extends StatelessWidget {
  const IssuanceText(
    this.text, {
    this.color = BrandColors.textSecondary,
    this.weight = AppTypography.body,
    this.size = 13,
    super.key,
  });

  final String text;
  final Color color;
  final FontWeight weight;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: s3Type(size, weight, color, height: 1.5));
}

/// An icon and a line of fact: the fee, the processing time, the office.
class IssuanceFact extends StatelessWidget {
  const IssuanceFact({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TaytayIcon(
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: 16,
              color: BrandColors.taytayBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: IssuanceText(text, color: BrandColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Somebody's own words, framed and attributed: what the office asked for,
/// its reason, when and where to claim, or the resident's own note.
class IssuanceQuote extends StatelessWidget {
  const IssuanceQuote({
    required this.label,
    required this.text,
    this.tone = IssuanceQuoteTone.info,
    super.key,
  });

  final String label;
  final String text;
  final IssuanceQuoteTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color fill) = switch (tone) {
      IssuanceQuoteTone.info => (
        BrandColors.taytayBlue,
        BrandColors.chipBlueBg,
      ),
      IssuanceQuoteTone.action => (
        BrandColors.warning,
        BrandColors.chipAmberBg,
      ),
      IssuanceQuoteTone.ready => (BrandColors.success, BrandColors.chipGreenBg),
      IssuanceQuoteTone.refused => (BrandColors.danger, BrandColors.chipRedBg),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border(left: BorderSide(color: ink, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: s3Type(11, AppTypography.black, ink),
          ),
          const SizedBox(height: 4),
          IssuanceText(text, color: BrandColors.textPrimary),
        ],
      ),
    );
  }
}

enum IssuanceQuoteTone { info, action, ready, refused }

/// The request's history as the verification pages draw progress: one disc
/// per move, newest last, with the words that came with each move beneath it.
///
/// The [Timeline] row holds one line, so each move is its own one-step
/// timeline and the message follows it rather than being squeezed into it.
class IssuanceHistoryTimeline extends StatelessWidget {
  const IssuanceHistoryTimeline({required this.detail, super.key});

  final IssuanceRequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final List<IssuanceHistoryEntry> history = detail.history;
    final IssuanceStatus? status = detail.status;
    final String? upcoming = switch (status) {
      IssuanceStatus.submitted ||
      IssuanceStatus.underReview ||
      IssuanceStatus.needsInfo ||
      IssuanceStatus.approved => 'Ready to claim',
      IssuanceStatus.readyForPickup => 'Claimed at the office',
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < history.length; i++) ...<Widget>[
          Timeline(
            key: ValueKey<String>('issuance-history-$i'),
            steps: <TimelineStep>[
              TimelineStep(
                icon: TaytayIcons.check,
                title: issuanceHistoryLine(
                  from: history[i].from,
                  to: history[i].to,
                ),
                detail: _when(history[i]),
                tone: i == history.length - 1 && !(status?.isFinished ?? false)
                    ? TimelineTone.current
                    : TimelineTone.done,
              ),
            ],
          ),
          if (_words(history[i]) case final String words)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 6),
              child: IssuanceQuote(
                label: history[i].by == IssuanceActor.resident
                    ? 'Your note'
                    : 'From the office',
                text: words,
              ),
            ),
        ],
        if (upcoming != null)
          Timeline(
            steps: <TimelineStep>[
              TimelineStep(
                icon: TaytayIcons.clock,
                title: upcoming,
                detail: 'You will see it here',
                tone: TimelineTone.upcoming,
              ),
            ],
          ),
      ],
    );
  }

  static String _when(IssuanceHistoryEntry entry) {
    final String date = issuanceDate(entry.at);
    return switch (entry.by) {
      IssuanceActor.resident => '$date · You',
      IssuanceActor.office => '$date · Office',
      IssuanceActor.unknown => date,
    };
  }

  /// The message, or the claim details on the move that set them.
  static String? _words(IssuanceHistoryEntry entry) =>
      entry.message ?? entry.claimDetails;
}

/// What the resident is told when a verified-only step is out of reach.
///
/// It explains; it does not decide. The route guard keeps the form closed and
/// the server refuses an unverified request whatever this shows.
class IssuanceAccessNotice extends StatelessWidget {
  const IssuanceAccessNotice({required this.decision, super.key});

  final AccessDecision decision;

  @override
  Widget build(BuildContext context) {
    final (String title, String body, String action, AppRoute route)? copy =
        switch (decision) {
          AccessNeedsAuthentication() => (
            'Sign in to request a document',
            'You can read what each document needs now. To send a request, '
                'sign in with a verified Taytay account.',
            'Sign in',
            AppRoute.signIn,
          ),
          AccessNeedsVerification() => (
            'Verify your account first',
            'Only verified Taytay residents can send a document request, '
                'because the office issues it in your name. You can read what '
                'each document needs now.',
            'Go to verification',
            AppRoute.verification,
          ),
          AccessAllowed() || AccessPending() => null,
        };
    if (copy == null) return const SizedBox.shrink();
    return Container(
      key: const Key('issuance-access-notice'),
      margin: const EdgeInsets.only(bottom: s3CardGap),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.chipAmberBg,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.lock,
                semanticLabel: '',
                excludeSemantics: true,
                size: 18,
                color: BrandColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    copy.$1,
                    style: s3Type(
                      14,
                      AppTypography.black,
                      BrandColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          IssuanceText(copy.$2, color: BrandColors.textPrimary),
          const SizedBox(height: 10),
          SecondaryButton(
            label: copy.$3,
            onPressed: () => context.goNamed(copy.$4.routeName),
          ),
        ],
      ),
    );
  }
}

/// A full-surface load failure, in this app's words.
class IssuanceLoadFailure extends StatelessWidget {
  const IssuanceLoadFailure({
    required this.failure,
    required this.onRetry,
    this.what = 'this',
    super.key,
  });

  final AppFailure failure;
  final VoidCallback onRetry;
  final String what;

  @override
  Widget build(BuildContext context) {
    final bool offline = failure is NetworkFailure || failure is TimeoutFailure;
    final String title = switch (failure) {
      NetworkFailure() || TimeoutFailure() => 'You are offline',
      NotFoundFailure() => 'Not found',
      _ => 'Could not load $what',
    };
    final String body = switch (failure) {
      NetworkFailure() || TimeoutFailure() =>
        'Taytay LGU could not be reached. Check your connection and try again.',
      NotFoundFailure() =>
        'This is not available. It may have been removed, or it belongs to '
            'another account.',
      _ => failure.residentMessage,
    };
    return ListView(
      padding: s3PagePadding,
      children: <Widget>[
        IssuanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              IconTile(
                icon: offline ? TaytayIcons.wifiOff : TaytayIcons.circleAlert,
                fill: BrandColors.chipRedBg,
                ink: BrandColors.danger,
                size: 52,
                iconSize: 24,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: s3Type(15, AppTypography.black, BrandColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: s3Type(
                  13,
                  AppTypography.body,
                  BrandColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (failure.requestId case final String reference) ...<Widget>[
                const SizedBox(height: 6),
                SelectableText(
                  'Reference: $reference',
                  textAlign: TextAlign.center,
                  style: s3Type(11, FontWeight.w400, BrandColors.textMuted),
                ),
              ],
              if (failure is! NotFoundFailure) ...<Widget>[
                const SizedBox(height: 12),
                PrimaryButton(label: 'Try again', onPressed: onRetry),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
