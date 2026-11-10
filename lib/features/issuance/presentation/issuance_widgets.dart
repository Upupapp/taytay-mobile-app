import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_status.dart';

/// The frame every document-request screen sits in: the blue header with its
/// back control, the offline strip (these routes sit outside the tab shell),
/// a scrolling body, and an optional footer action.
///
/// [white] is the Office / RegDetails page (detail sheet, form); otherwise
/// the `#F4F6FA` list page. [bottom] goes under the header title, e.g. the
/// search field.
class IssuanceScaffold extends StatelessWidget {
  const IssuanceScaffold({
    required this.title,
    required this.body,
    this.footer,
    this.bottom,
    this.white = false,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? footer;
  final Widget? bottom;
  final bool white;

  @override
  Widget build(BuildContext context) {
    final Widget? footer = this.footer;
    return Scaffold(
      backgroundColor: white ? BrandColors.white : BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlueHeader(title: title, showBack: true, bottom: bottom),
          const OfflineBanner(),
          Expanded(child: body),
          if (footer != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.formGutter,
                  Spacing.md,
                  Spacing.formGutter,
                  Spacing.lg,
                ),
                child: footer,
              ),
            ),
        ],
      ),
    );
  }
}

/// The page padding of a list body: 16 at the sides, 14 under the header.
EdgeInsets issuanceListPadding(BuildContext context) => EdgeInsets.fromLTRB(
  Spacing.lg,
  Spacing.section,
  Spacing.lg,
  Spacing.xl + MediaQuery.paddingOf(context).bottom,
);

/// The colour a status pill carries. The words on it are always the label, so
/// colour is never the only signal.
PillTone issuanceStatusTone(IssuanceStatus? status) => switch (status) {
  IssuanceStatus.submitted || IssuanceStatus.underReview => PillTone.blue,
  IssuanceStatus.needsInfo => PillTone.gold,
  IssuanceStatus.approved => PillTone.green,
  IssuanceStatus.readyForPickup => PillTone.gold,
  IssuanceStatus.released => PillTone.green,
  IssuanceStatus.rejected => PillTone.red,
  IssuanceStatus.cancelled || null => PillTone.neutral,
};

class IssuanceStatusChip extends StatelessWidget {
  const IssuanceStatusChip({required this.status, super.key});

  final IssuanceStatus? status;

  @override
  Widget build(BuildContext context) => StatusPill(
    label: issuanceStatusLabel(status),
    tone: issuanceStatusTone(status),
  );
}

/// `05 Nov 2026`, in Manila time, or a dash when the server sent none.
String issuanceDate(DateTime? instant) =>
    instant == null ? '—' : ManilaTime.formatDate(instant);

/// A section of a white page (Office `.sheet`, RegDetails): a filled soft
/// card with an optional 15 / 600 heading.
class IssuanceCard extends StatelessWidget {
  const IssuanceCard({required this.child, this.title, super.key});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? heading = title;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.section),
      child: SoftCard(
        filled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (heading != null) ...<Widget>[
              IssuanceHeading(heading),
              const SizedBox(height: Spacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A section title (15 / 600, ink), announced as a heading.
class IssuanceHeading extends StatelessWidget {
  const IssuanceHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
    ),
  );
}

/// Body copy (13.5 / 500, 1.5). [small] is the 12.5 supporting line.
class IssuanceText extends StatelessWidget {
  const IssuanceText(
    this.text, {
    this.color = BrandColors.text,
    this.small = false,
    super.key,
  });

  final String text;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: (small ? AppTypography.listDetail : AppTypography.bodyStyle)
        .copyWith(color: color, height: 1.5),
  );
}

/// An icon and a line of fact: the fee, the processing time, the office.
class IssuanceFact extends StatelessWidget {
  const IssuanceFact({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xxs),
            child: TaytayIcon(
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm - Spacing.xxs,
              color: BrandColors.blue,
            ),
          ),
          const SizedBox(width: Spacing.sm + Spacing.xxs),
          Expanded(child: IssuanceText(text, color: BrandColors.ink)),
        ],
      ),
    );
  }
}

/// Somebody's own words, framed and attributed: what the office asked for,
/// its reason, when and where to claim, or the resident's own note.
///
/// The soft note of the redesign (`.soft .note`): a tinted panel with the
/// category label (10.5 / 800, upper case) over the words.
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
      IssuanceQuoteTone.info => (BrandColors.blue, BrandColors.blue50),
      IssuanceQuoteTone.action => (BrandColors.goldInk, BrandColors.gold50),
      IssuanceQuoteTone.ready => (BrandColors.green, BrandColors.green50),
      IssuanceQuoteTone.refused => (BrandColors.redInk, BrandColors.red50),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.note),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.section,
          Spacing.md,
          Spacing.section,
          Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: AppTypography.category.copyWith(color: ink),
            ),
            const SizedBox(height: Spacing.xs),
            IssuanceText(text, color: BrandColors.ink),
          ],
        ),
      ),
    );
  }
}

enum IssuanceQuoteTone { info, action, ready, refused }

/// The request's history, oldest first: a dot per move on a hairline rail,
/// the move in words with its date, and the words that came with it.
/// The next step, when there is one, is drawn hollow at the end.
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
        for (var i = 0; i < history.length; i++)
          _HistoryRow(
            key: ValueKey<String>('issuance-history-$i'),
            title: issuanceHistoryLine(
              from: history[i].from,
              to: history[i].to,
            ),
            when: _when(history[i]),
            current: i == history.length - 1 && !(status?.isFinished ?? false),
            last: i == history.length - 1 && upcoming == null,
            words: _words(history[i]),
            wordsLabel: history[i].by == IssuanceActor.resident
                ? 'Your note'
                : 'From the office',
          ),
        if (upcoming != null)
          _HistoryRow(
            title: upcoming,
            when: 'You will see it here',
            upcoming: true,
            last: true,
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.when,
    required this.last,
    this.current = false,
    this.upcoming = false,
    this.words,
    this.wordsLabel = 'From the office',
    super.key,
  });

  final String title;
  final String when;
  final bool last;
  final bool current;
  final bool upcoming;
  final String? words;
  final String wordsLabel;

  @override
  Widget build(BuildContext context) {
    final String? words = this.words;
    final Color dot = upcoming
        ? BrandColors.white
        : current
        ? BrandColors.blue
        : BrandColors.green;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The rail is decoration: every row says its step and date in text.
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Column(
                children: <Widget>[
                  Container(
                    width: Spacing.md,
                    height: Spacing.md,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      border: upcoming
                          ? Border.all(color: BrandColors.line2, width: 2)
                          : null,
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: Spacing.xxs,
                        color: BrandColors.divider,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.listTitle.copyWith(
                      color: upcoming ? BrandColors.muted : BrandColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    when,
                    style: AppTypography.small.copyWith(
                      fontWeight: AppTypography.medium,
                      color: BrandColors.muted,
                    ),
                  ),
                  if (words != null) ...<Widget>[
                    const SizedBox(height: Spacing.sm),
                    IssuanceQuote(label: wordsLabel, text: words),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    return Padding(
      key: const Key('issuance-access-notice'),
      padding: const EdgeInsets.only(bottom: Spacing.section),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.gold50,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const IconTile.lucide(
                    icon: TaytayIcons.lock,
                    tone: TileTone.gold,
                    tileSize: IconTileSize.small,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            copy.$1,
                            style: AppTypography.listTitle.copyWith(
                              color: BrandColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        IssuanceText(copy.$2),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              FilledButton(
                style: TaytayButtonStyles.soft(),
                onPressed: () => context.goNamed(copy.$4.routeName),
                child: Text(copy.$3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-surface load failure, in this app's words: the shared error state,
/// with the offline art for a network failure and Try again unless the thing
/// is gone.
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
      padding: issuanceListPadding(context),
      children: <Widget>[
        ErrorState(
          title: title,
          message: body,
          offline: offline,
          boxed: true,
          onRetry: failure is NotFoundFailure ? null : onRetry,
          details: <Widget>[
            if (failure.requestId case final String reference)
              SelectableText(
                'Reference: $reference',
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(color: BrandColors.muted),
              ),
          ],
        ),
      ],
    );
  }
}
