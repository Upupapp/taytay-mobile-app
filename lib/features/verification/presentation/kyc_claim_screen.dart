import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../registration/domain/registration_domain.dart';
import '../domain/kyc_claim.dart';
import 'kyc_claim_controller.dart';

/// The form that opens a resident's KYC case — the door F14 kept shut.
///
/// ---
///
/// **What this screen asks for, and nothing more.** Name, date of birth, sex,
/// barangay, street address. That is exactly what `POST me/kyc` validates, and
/// the list is short on purpose: every field here becomes a `claimed_*` column
/// in a municipal review queue, read by staff, kept for as long as the retention
/// schedule says. A field added "in case the office wants it" is a field the
/// office never asked for and cannot un-collect.
///
/// **No mobile number, no email, no PhilSys number.** The first two are already
/// on the account and the server takes them from the authenticated actor; the
/// third is what the office looks up, never what an applicant asserts.
///
/// **No identity document and no selfie.** A KYC case has nowhere to put one
/// (F28), and a screen that collected a photograph of somebody's PhilID and
/// dropped it would have taken the most sensitive thing this app can hold, for
/// nothing.
///
/// **Nothing is sent by opening a case.** The case is a draft the resident owns
/// until they send it from the status screen. Splitting the two is deliberate:
/// somebody who mistyped a birth date has not already spent their place in a
/// municipal queue.
class KycClaimScreen extends StatefulWidget {
  const KycClaimScreen({super.key});

  @override
  State<KycClaimScreen> createState() => _KycClaimScreenState();
}

class _KycClaimScreenState extends State<KycClaimScreen> {
  late final KycClaimController _controller;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final dependencies = AppDependencies.of(context);
    _controller = KycClaimController(
      directory: dependencies.barangayDirectory,
      repository: dependencies.verificationRepository,
    )..addListener(_onChanged);
    _controller.loadDirectory();
  }

  void _onChanged() {
    if (!mounted) return;
    // The case exists. Back to the status screen, which is the one place that
    // says where an application stands — this screen must never become a second
    // source of truth about it.
    if (_controller.opened) {
      context.goNamed(AppRoute.verification.routeName);
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller.birthDate ?? DateTime(now.year - 30),
      // A municipal register holds people over a century old. The upper bound is
      // yesterday, because the server's rule is `before:today` and a form that
      // offers a date the server refuses is a form that lies.
      firstDate: DateTime(now.year - 120),
      lastDate: now.subtract(const Duration(days: 1)),
      helpText: AppStrings.of(context).fieldBirthDate,
    );
    if (picked != null) _controller.setBirthDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final directoryFailure = _controller.directoryFailure;
    final failure = _controller.failure;
    final birthDate = _controller.birthDate;
    final sex = _controller.sex;
    final AppStrings strings = AppStrings.of(context);

    return AuthFormPage(
      title: strings.gateSheetVerifyTitle,
      subtitle: 'Bayan ng Taytay · Rizal',
      child: _controller.loadingDirectory
          ? LoadingSkeleton(
              layout: SkeletonLayout.detail,
              count: 1,
              semanticLabel: strings.verifKycLoadingBarangays,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const OfflineBanner(),
                Text(
                  strings.verifKycIntro,
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.text,
                  ),
                ),
                const SizedBox(height: Spacing.formGap),

                if (directoryFailure != null) ...<Widget>[
                  // Never an empty picker. An empty dropdown tells a resident
                  // their barangay is not in Taytay, which is a worse thing to
                  // be told than that the list could not be loaded.
                  SoftNote(
                    tone: NoteTone.warning,
                    heading: strings.verifKycBarangaysFailed,
                    message: localisedResidentMessage(
                      context,
                      directoryFailure,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  FilledButton(
                    style: TaytayButtonStyles.soft(),
                    onPressed: _controller.loadDirectory,
                    child: Text(strings.actionTryAgain),
                  ),
                  const SizedBox(height: Spacing.formGap),
                ],

                if (failure != null) ...<Widget>[
                  SoftNote(
                    tone: NoteTone.warning,
                    heading: strings.verifKycStartFailed,
                    message: localisedResidentMessage(context, failure),
                  ),
                  const SizedBox(height: Spacing.formGap),
                ],

                FieldLabel(
                  label: strings.fieldFirstName,
                  hint: strings.verifKycAsOnId,
                ),
                TextField(
                  enabled: !_controller.submitting,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const <String>[AutofillHints.givenName],
                  decoration: InputDecoration(
                    labelText: strings.fieldFirstName,
                  ),
                  onChanged: _controller.setGivenName,
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(label: strings.fieldMiddleName, required: false),
                TextField(
                  enabled: !_controller.submitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: strings.fieldMiddleName,
                  ),
                  onChanged: _controller.setMiddleName,
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(label: strings.fieldLastName),
                TextField(
                  enabled: !_controller.submitting,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const <String>[AutofillHints.familyName],
                  decoration: InputDecoration(labelText: strings.fieldLastName),
                  onChanged: _controller.setFamilyName,
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(
                  label: strings.verifSuffix,
                  required: false,
                  hint: 'Jr, Sr, III.',
                ),
                TextField(
                  enabled: !_controller.submitting,
                  decoration: InputDecoration(labelText: strings.verifSuffix),
                  onChanged: _controller.setSuffix,
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(label: strings.fieldBirthDate),
                OutlinedButton.icon(
                  onPressed: _controller.submitting ? null : _pickBirthDate,
                  icon: const TaytayIcon(
                    icon: TaytayIcons.calendar,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: IconSizes.sm,
                    color: BrandColors.blue,
                  ),
                  label: Text(
                    birthDate == null
                        ? strings.verifKycChooseBirthDate
                        : _formatDate(birthDate),
                  ),
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(
                  label: strings.fieldSex,
                  hint: strings.verifKycSexHint,
                ),
                // Two options because the civil register holds two, and this
                // claim is matched against it. Not a gender field — see
                // [ClaimedSex].
                SegmentedButton<ClaimedSex>(
                  segments: <ButtonSegment<ClaimedSex>>[
                    ButtonSegment<ClaimedSex>(
                      value: ClaimedSex.female,
                      label: Text(strings.verifSexFemale),
                    ),
                    ButtonSegment<ClaimedSex>(
                      value: ClaimedSex.male,
                      label: Text(strings.verifSexMale),
                    ),
                  ],
                  emptySelectionAllowed: true,
                  selected: <ClaimedSex>{?sex},
                  onSelectionChanged: _controller.submitting
                      ? null
                      : (Set<ClaimedSex> selected) {
                          if (selected.isNotEmpty) {
                            _controller.setSex(selected.first);
                          }
                        },
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(
                  label: strings.fieldBarangay,
                  hint: strings.profileHintBarangay,
                ),
                DropdownButtonFormField<Barangay>(
                  initialValue: _controller.barangay,
                  decoration: InputDecoration(labelText: strings.fieldBarangay),
                  items: <DropdownMenuItem<Barangay>>[
                    for (final Barangay barangay in _controller.barangays)
                      DropdownMenuItem<Barangay>(
                        value: barangay,
                        child: Text(barangay.name),
                      ),
                  ],
                  onChanged: _controller.submitting
                      ? null
                      : (Barangay? value) {
                          if (value != null) _controller.setBarangay(value);
                        },
                ),
                const SizedBox(height: Spacing.formGap),

                FieldLabel(label: strings.profileFieldStreetAddress),
                TextField(
                  enabled: !_controller.submitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: strings.fieldStreetAddress,
                  ),
                  onChanged: _controller.setStreetAddress,
                ),
                const SizedBox(height: Spacing.xl),

                WhyWeAsk(
                  title: strings.verifKycWhyTitle,
                  purpose: strings.verifKycWhyPurpose,
                  whoSeesIt: strings.verifKycWhyWho,
                  ifYouDecline: strings.verifKycWhyDecline,
                ),
                const SizedBox(height: Spacing.xl),

                AppButton(
                  label: strings.verifKycSaveContinue,
                  loading: _controller.submitting,
                  onPressed: _controller.canSubmit ? _controller.submit : null,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  strings.verifKycNothingSentYet,
                  style: AppTypography.small.copyWith(color: BrandColors.muted),
                ),
              ],
            ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
