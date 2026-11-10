import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
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
    final acknowledgement = release.acknowledgement?.known;
    final String? amount = release.amountDescription;
    final DateTime? scheduled = release.scheduledAt;
    final String? location = release.location;
    final String? instructions = release.instructions;

    return CasePanel(
      icon: TaytayIcons.handHeart,
      title: 'What you are receiving',
      children: <Widget>[
        if (amount != null) CaseLine(label: 'Approved', value: amount),
        if (scheduled != null)
          CaseLine(label: 'When', value: formatCaseDate(scheduled)),
        if (location != null) CaseLine(label: 'Where', value: location),

        if (instructions != null) ...<Widget>[
          const SizedBox(height: Spacing.xs),
          Text(instructions, style: _bodyInk),
        ],

        if (acknowledgement != null &&
            acknowledgement != ReleaseAcknowledgement.notRequired) ...<Widget>[
          const SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TaytayIcon(
                icon: acknowledgement == ReleaseAcknowledgement.acknowledged
                    ? TaytayIcons.circleCheck
                    : TaytayIcons.hourglass,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.muted,
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
                  style: AppTypography.listDetail.copyWith(
                    color: BrandColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Where the LGU sent a case it does not handle itself.
class ReferralCard extends StatelessWidget {
  const ReferralCard({required this.referral, super.key});

  final ReferralDetail referral;

  @override
  Widget build(BuildContext context) {
    final String? service = referral.serviceRequested;
    final status = referral.status;
    final String? contact = referral.contact;
    final String? instructions = referral.instructions;

    return CasePanel(
      icon: TaytayIcons.building2,
      title: 'Referred to another office',
      children: <Widget>[
        CaseLine(label: 'Office', value: referral.destination),
        if (service != null) CaseLine(label: 'For', value: service),
        if (status != null)
          CaseLine(
            label: 'Referral status',
            value: referralStatusLabel(status.known),
          ),
        // Shown only when the backend sent one, because a contact detail is
        // published deliberately or not at all.
        if (contact != null) CaseLine(label: 'Contact', value: contact),

        if (instructions != null) ...<Widget>[
          const SizedBox(height: Spacing.xs),
          Text(instructions, style: _bodyInk),
        ],
      ],
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

/// A part of a request on the white sheet: a filled soft card with a soft
/// icon square, a heading, and its lines.
class CasePanel extends StatelessWidget {
  const CasePanel({
    required this.icon,
    required this.title,
    required this.children,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      filled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: ComponentSizes.tileSmall,
                height: ComponentSizes.tileSmall,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandColors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: TaytayIcon(
                  icon: icon,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: IconSizes.sm,
                  color: BrandColors.blue,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// A label and its value on one line; nothing when the value is empty.
class CaseLine extends StatelessWidget {
  const CaseLine({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTypography.small.copyWith(
                fontWeight: AppTypography.medium,
                color: BrandColors.muted,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: _bodyInk),
          ),
        ],
      ),
    );
  }
}

final TextStyle _bodyInk = AppTypography.bodyStyle.copyWith(
  color: BrandColors.ink,
);

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
