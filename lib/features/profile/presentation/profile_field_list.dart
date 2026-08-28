import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../domain/profile_fields.dart';
import '../domain/resident_profile_detail.dart';

/// One ownership group, with its heading, its explanation and its affordance.
///
/// ---
///
/// **The heading and the icon are the acceptance criterion.** A resident sees
/// "Your account details — you can change these yourself" above one group, and
/// "Confirmed by Taytay LGU — only the LGU can change them" above the other,
/// with a chevron on one and a lock on the other. The difference is legible
/// before anything is tapped, and it is stated in words as well as in iconography
/// so it survives monochrome vision (WCAG 2.2 §1.4.1).
///
/// **A locked row is still tappable.** It opens the correction path rather than
/// doing nothing: a row that ignores a tap reads as broken, and the resident who
/// tapped it is exactly the one who thinks the value is wrong.
class ProfileFieldList extends StatelessWidget {
  const ProfileFieldList({
    required this.ownership,
    required this.detail,
    required this.loading,
    required this.unavailable,
    this.onEdit,
    super.key,
  });

  final FieldOwnership ownership;
  final ResidentProfileDetail? detail;
  final bool loading;

  /// True when the record could not be read at all.
  final bool unavailable;

  /// Present only for the group the resident owns.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // THE OFFICE'S GROUPING, NOT THIS APP'S (C-13).
    //
    // `ResidentProfileField.ownedBy` is a declaration written into the enum;
    // `detail.fieldsOwnedBy` is what the server published on this response. They
    // disagreed on `street_address` — the office lets a resident change it and
    // this heading told them "only the LGU can change them", which is a wrong
    // statement about their own rights rather than a cosmetic mismatch.
    //
    // The static list remains the fallback for a response that did not say.
    final fields =
        detail?.fieldsOwnedBy(ownership) ??
        ResidentProfileField.ownedBy(ownership);
    final editable = ownership.isEditableInApp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              editable ? Icons.edit_outlined : Icons.verified_outlined,
              size: IconSizes.md,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  profileSectionCopy(context, ownership).title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          profileSectionCopy(context, ownership).explanation,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (final field in fields)
                  _FieldRow(
                    field: field,
                    value: detail?.valueOf(field),
                    unavailable: unavailable,
                    onEdit: onEdit,
                  ),
              ],
            ),
          ),
        if (unavailable) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Text(
            editable
                ? 'Taytay LGU has not switched on account details in this app '
                      'yet. Your account still works.'
                : 'Taytay LGU has not switched on your record in this app yet. '
                      'The municipal hall can tell you what is on file.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// One field: its label, its value if known, and what can be done about it.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.value,
    required this.unavailable,
    this.onEdit,
  });

  final ResidentProfileField field;
  final String? value;
  final bool unavailable;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = value != null && value!.isNotEmpty;

    return ListTile(
      title: Text(profileFieldLabel(context, field)),
      subtitle: Text(
        known
            ? value!
            // Never "—" or a blank: an empty row on a government record reads
            // as data loss. Saying which it is costs one sentence.
            : unavailable
            ? 'Not available in this app yet'
            : 'Not on file',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: known
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
          fontStyle: known ? null : FontStyle.italic,
        ),
      ),
      trailing: Icon(
        field.isEditableInApp ? Icons.chevron_right : Icons.lock_outline,
        color: field.isEditableInApp
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
      ),
      // The lock icon alone would be decoration; the semantic label is what a
      // screen reader announces, and it has to carry the same meaning.
      onTap: field.isEditableInApp
          ? onEdit
          : () => CanonicalFieldSheet.show(context, field),
    );
  }
}

/// Explains why a canonical field cannot be edited, and what to do instead.
///
/// ---
///
/// **This is the correction pattern, and it is a sentence rather than a form**
/// (acceptance 2). The committed contract defines no resident-initiated
/// correction endpoint: `PATCH /me/profile` is contact-only, and
/// `PATCH /api/v1/residents/{id}` needs a staff permission this app must never
/// hold. A form here would collect a resident's evidence and have nowhere to
/// send it — and a submission that silently goes nowhere is worse than a clear
/// instruction, because the resident who followed the instruction gets their
/// record fixed.
///
/// The one shortcut offered is verification: if the LGU has already asked them
/// for a correction there, answering it is cheaper than a second trip.
abstract final class CanonicalFieldSheet {
  static Future<void> show(
    BuildContext context,
    ResidentProfileField field,
  ) async {
    final router = GoRouter.of(context);
    final session = AppDependencies.of(context).session.state;
    // A switch rather than an equality test: exhaustive over the level, so a
    // new access level cannot silently fall into the wrong branch, and no
    // scattered comparison creeps back in (TAB 10's rule).
    final midVerification = switch (session.accessLevel) {
      AccessLevel.unverified => true,
      AccessLevel.guest || AccessLevel.verified => false,
    };

    await AppSheet.show<void>(
      context: context,
      title: CanonicalCorrection.title,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              profileFieldLabel(context, field),
              style: theme.textTheme.titleMedium,
            ),
            if (profileFieldHint(context, field) case final hint?) ...<Widget>[
              const SizedBox(height: Spacing.xs),
              Text(
                hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            Text(
              CanonicalCorrection.explanation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              CanonicalCorrection.nextStep,
              style: theme.textTheme.bodyMedium,
            ),
            if (midVerification) ...<Widget>[
              const SizedBox(height: Spacing.md),
              Text(
                CanonicalCorrection.duringVerification,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Spacing.lg),
              AppButton(
                label: 'Check my verification',
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  router.goNamed(AppRoute.verification.routeName);
                },
              ),
            ] else ...<Widget>[
              const SizedBox(height: Spacing.lg),
              AppButton(
                label: 'Close',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The verification state, as a badge.
///
/// Reads the session's access level rather than fetching anything: the level
/// came from the server's own tier and is already the app's single source of
/// truth for it (TAB 08). Fetching again here would be a second `/me/` read for
/// a fact the app already holds.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = AppDependencies.of(context).session.accessLevel;

    final (
      String label,
      IconData icon,
      Color background,
      Color foreground,
    ) = switch (level) {
      AccessLevel.guest => (
        'Not signed in',
        Icons.person_outline,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurface,
      ),
      AccessLevel.unverified => (
        'Not yet verified',
        Icons.pending_outlined,
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      AccessLevel.verified => (
        'Verified by Taytay LGU',
        Icons.verified_outlined,
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        // A badge is exactly the component that becomes colour-only. The icon
        // and the words carry the state; the colour reinforces it.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: IconSizes.sm, color: foreground),
            const SizedBox(width: Spacing.sm),
            // Flexible, not a bare Text: "Verified by Taytay LGU" at a large
            // text scale is wider than a phone, and a badge that overflows is a
            // badge whose meaning is cut off.
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
