import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/assistance_history.dart';

/// What a resident is receiving, and how to collect it.
///
/// ---
///
/// **Every field is optional and every one is omitted when absent.** An office
/// that has approved a release but not yet scheduled it should produce a card
/// saying what was approved and nothing about a date — not a card with "Date:
/// —" in it, which reads as a system that has lost the information rather than
/// one that does not have it yet.
///
/// **The amount is printed exactly as the server sent it.** It may be an in-kind
/// description rather than money, and where it is money the figure a resident
/// reads must be the figure the office approved, character for character. This
/// widget does not parse, round, or format it.
///
/// **Nothing about funding appears**, because `ReleaseDetail` has no field for
/// it. No budget line, no fund source, no disbursement batch, no other
/// beneficiary, no manifest.
class ReleaseCard extends StatelessWidget {
  const ReleaseCard({required this.release, super.key});

  final ReleaseDetail release;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acknowledgement = release.acknowledgement?.known;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.card_giftcard_outlined,
                size: IconSizes.md,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'What you are receiving',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          if (release.amountDescription != null)
            _Line(label: 'Approved', value: release.amountDescription!),
          if (release.scheduledAt != null)
            _Line(label: 'When', value: formatCaseDate(release.scheduledAt!)),
          if (release.location != null)
            _Line(label: 'Where', value: release.location!),

          if (release.instructions != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(release.instructions!, style: theme.textTheme.bodyMedium),
          ],

          if (acknowledgement != null &&
              acknowledgement !=
                  ReleaseAcknowledgement.notRequired) ...<Widget>[
            const SizedBox(height: Spacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  acknowledgement == ReleaseAcknowledgement.acknowledged
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
                  size: IconSizes.sm,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    acknowledgement == ReleaseAcknowledgement.acknowledged
                        ? 'You have confirmed you received this.'
                        // Stated, not offered as a button: acknowledging receipt
                        // is a signature at a counter, and an app that let a
                        // resident tap it in advance would be recording a
                        // confirmation for something they may not have.
                        : 'Taytay LGU will ask you to confirm receipt when you '
                              'collect this.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the LGU sent a case it does not handle itself.
class ReferralCard extends StatelessWidget {
  const ReferralCard({required this.referral, super.key});

  final ReferralDetail referral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.alt_route_outlined,
                size: IconSizes.md,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Referred to another office',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          _Line(label: 'Office', value: referral.destination),
          if (referral.serviceRequested != null)
            _Line(label: 'For', value: referral.serviceRequested!),
          if (referral.status != null)
            _Line(
              label: 'Referral status',
              value: referralStatusLabel(referral.status!.known),
            ),
          // Shown only when the backend sent one, because a contact detail is
          // published deliberately or not at all.
          if (referral.contact != null)
            _Line(label: 'Contact', value: referral.contact!),

          if (referral.instructions != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(referral.instructions!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Resident-facing wording for a referral's own lifecycle.
///
/// `declined` is worded so it reads as a fact about the receiving office rather
/// than a judgement about the resident, and it always points somewhere: a
/// referral that stops with no next step is how someone gives up on a service
/// they are entitled to.
String referralStatusLabel(ReferralStatus? status) => switch (status) {
  ReferralStatus.sent => 'Sent to that office',
  ReferralStatus.accepted => 'That office has taken it on',
  ReferralStatus.declined =>
    'That office could not take it on — Taytay LGU can tell you what happens '
        'next',
  ReferralStatus.completed => 'Finished by that office',
  null => 'Being processed',
};

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// `dd MMM yyyy`, written out because a numeric date is ambiguous between
/// Philippine and US conventions and there is no localisation seam yet.
///
/// Shared by the case screen, the release card and the history list so one
/// record does not render three different ways.
String formatCaseDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}
