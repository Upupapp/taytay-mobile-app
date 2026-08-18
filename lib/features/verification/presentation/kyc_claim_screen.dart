import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/form_support.dart';
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
      helpText: 'Date of birth',
    );
    if (picked != null) _controller.setBirthDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: SafeArea(
        child: _controller.loadingDirectory
            ? const AppLoadingView(message: 'Loading barangays…')
            : ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: <Widget>[
                  Text(
                    'Taytay LGU checks these details against the municipal '
                    'resident register. Enter them as they appear on your birth '
                    'certificate or valid ID.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  if (_controller.directoryFailure != null) ...<Widget>[
                    // Never an empty picker. An empty dropdown tells a resident
                    // their barangay is not in Taytay, which is a worse thing to
                    // be told than that the list could not be loaded.
                    AppBanner(
                      tone: BannerTone.warning,
                      title: 'Could not load barangays',
                      message: _controller.directoryFailure!.residentMessage,
                      action: AppButton(
                        label: 'Try again',
                        variant: AppButtonVariant.secondary,
                        fullWidth: false,
                        onPressed: _controller.loadDirectory,
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],

                  if (_controller.failure != null) ...<Widget>[
                    AppBanner(
                      tone: BannerTone.warning,
                      title: 'Could not start your verification',
                      message: _controller.failure!.residentMessage,
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],

                  const FieldLabel(
                    label: 'First name',
                    hint: 'As it appears on your ID.',
                  ),
                  TextField(
                    enabled: !_controller.submitting,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const <String>[AutofillHints.givenName],
                    decoration: const InputDecoration(labelText: 'First name'),
                    onChanged: _controller.setGivenName,
                  ),
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(label: 'Middle name', required: false),
                  TextField(
                    enabled: !_controller.submitting,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Middle name'),
                    onChanged: _controller.setMiddleName,
                  ),
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(label: 'Last name'),
                  TextField(
                    enabled: !_controller.submitting,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const <String>[AutofillHints.familyName],
                    decoration: const InputDecoration(labelText: 'Last name'),
                    onChanged: _controller.setFamilyName,
                  ),
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(
                    label: 'Suffix',
                    required: false,
                    hint: 'Jr, Sr, III.',
                  ),
                  TextField(
                    enabled: !_controller.submitting,
                    decoration: const InputDecoration(labelText: 'Suffix'),
                    onChanged: _controller.setSuffix,
                  ),
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(label: 'Date of birth'),
                  OutlinedButton.icon(
                    onPressed: _controller.submitting ? null : _pickBirthDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _controller.birthDate == null
                          ? 'Choose your date of birth'
                          : _formatDate(_controller.birthDate!),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(
                    label: 'Sex',
                    hint: 'As recorded on your birth certificate.',
                  ),
                  // Two options because the civil register holds two, and this
                  // claim is matched against it. Not a gender field — see
                  // [ClaimedSex].
                  SegmentedButton<ClaimedSex>(
                    segments: const <ButtonSegment<ClaimedSex>>[
                      ButtonSegment<ClaimedSex>(
                        value: ClaimedSex.female,
                        label: Text('Female'),
                      ),
                      ButtonSegment<ClaimedSex>(
                        value: ClaimedSex.male,
                        label: Text('Male'),
                      ),
                    ],
                    emptySelectionAllowed: true,
                    selected: <ClaimedSex>{
                      if (_controller.sex != null) _controller.sex!,
                    },
                    onSelectionChanged: _controller.submitting
                        ? null
                        : (Set<ClaimedSex> selected) {
                            if (selected.isNotEmpty) {
                              _controller.setSex(selected.first);
                            }
                          },
                  ),
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(
                    label: 'Barangay',
                    hint: 'Decides which barangay office serves you.',
                  ),
                  DropdownButtonFormField<Barangay>(
                    initialValue: _controller.barangay,
                    decoration: const InputDecoration(labelText: 'Barangay'),
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
                  const SizedBox(height: Spacing.lg),

                  const FieldLabel(label: 'Street address'),
                  TextField(
                    enabled: !_controller.submitting,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'House number and street',
                    ),
                    onChanged: _controller.setStreetAddress,
                  ),
                  const SizedBox(height: Spacing.xl),

                  const WhyWeAsk(
                    title: 'Why does Taytay LGU need these?',
                    purpose:
                        'Taytay LGU matches these details against the municipal '
                        'resident register to confirm you are who you say you '
                        'are.',
                    whoSeesIt:
                        'Staff reviewing verification for your barangay. Your '
                        'details are not shown to other residents and are not '
                        'used for anything else.',
                    ifYouDecline:
                        'You can keep using this app to browse municipal '
                        'services and announcements. You will not be able to '
                        'hold a digital ID or apply for assistance.',
                  ),
                  const SizedBox(height: Spacing.xl),

                  AppButton(
                    label: 'Save and continue',
                    loading: _controller.submitting,
                    onPressed: _controller.canSubmit
                        ? _controller.submit
                        : null,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Nothing is sent to Taytay LGU yet. You can check your '
                    'details before sending them for review.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
