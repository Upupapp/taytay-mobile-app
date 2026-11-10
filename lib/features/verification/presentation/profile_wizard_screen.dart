import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../domain/resident_record.dart';
import '../domain/resident_record_repository.dart';
import '../domain/verification_repository.dart';
import 'profile_wizard_page.dart';

/// Loads the resident's own profile for one wizard step.
///
/// The record stays in this [State]. Nothing is written onto the session.
class ProfileWizardScreen extends StatefulWidget {
  const ProfileWizardScreen({required this.step, this.preview, super.key});

  final ProfileWizardStep step;

  /// Skips the network. Capture and widget tests pass the record directly.
  final ResidentRecord? preview;

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  ResidentRecord? _record;
  DateTime? _submittedAt;
  Object? _failureMessage;
  bool _certified = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final ResidentRecord? preview = widget.preview;
    if (preview != null) {
      _record = preview;
      return;
    }
    _load();
  }

  ResidentRecordRepository? _repository() =>
      AppDependencies.of(context).residentRecordRepository;

  Future<void> _load() async {
    final ResidentRecordRepository? repository = _repository();
    if (repository == null) {
      setState(() => _failureMessage = 'Profile is not available right now.');
      return;
    }
    final result = await repository.load();
    if (!mounted) return;
    DateTime? submitted;
    if (widget.step == ProfileWizardStep.submitted &&
        result is Ok<ResidentRecord>) {
      final VerificationRepository verification = AppDependencies.of(
        context,
      ).verificationRepository;
      final status = await verification.loadOwnStatusDetail();
      if (!mounted) return;
      if (status case Ok(:final value)) submitted = value.submittedAt;
    }
    switch (result) {
      case Ok(:final value):
        setState(() {
          _record = value;
          _submittedAt = submitted;
          _failureMessage = null;
        });
      case Err(:final failure):
        setState(() => _failureMessage = failure.residentMessage);
    }
  }

  PersonalDraft _personal(ResidentRecord record) => PersonalDraft(
    givenName: record.givenName,
    middleName: record.middleName,
    familyName: record.familyName,
    suffix: record.suffix,
    sex: record.sex,
    birthdate: record.birthdate,
    civilStatus: record.civilStatus,
    mobile: record.mobile,
    email: record.email,
  );

  HouseholdDraft _household(ResidentRecord record) => HouseholdDraft(
    barangayId: record.barangayId,
    barangayName: record.barangayName,
    street: record.street,
    purok: record.purok,
    yearsAtAddress: record.yearsAtAddress,
    memberCount: record.memberCount,
    residenceType: record.residenceType,
  );

  Future<void> _continue(ResidentRecord record) async {
    final ResidentRecordRepository? repository = _repository();
    switch (widget.step) {
      case ProfileWizardStep.overview:
        context.goNamed(AppRoute.residentProfilePersonal.routeName);
        break;
      case ProfileWizardStep.personal:
        if (widget.preview == null && repository != null) {
          await repository.savePersonal(_personal(record));
        }
        if (!mounted) return;
        context.goNamed(AppRoute.residentProfileAddress.routeName);
        break;
      case ProfileWizardStep.household:
        if (widget.preview == null && repository != null) {
          await repository.saveHousehold(_household(record));
        }
        if (!mounted) return;
        context.goNamed(AppRoute.residentProfileReview.routeName);
        break;
      case ProfileWizardStep.review:
        if (!_certified) return;
        if (widget.preview == null && repository != null) {
          await repository.submit(
            personal: _personal(record),
            household: _household(record),
          );
        }
        if (!mounted) return;
        context.goNamed(AppRoute.residentProfileSubmitted.routeName);
        break;
      case ProfileWizardStep.submitted:
        context.goNamed(AppRoute.residentProfile.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ResidentRecord? record = _record;
    if (record == null) {
      final Object? message = _failureMessage;
      return Scaffold(
        backgroundColor: BrandColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const BlueHeader(title: 'Resident profile', showBack: true),
            const OfflineBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: <Widget>[
                  if (message == null)
                    const LoadingSkeleton(
                      layout: SkeletonLayout.detail,
                      count: 1,
                      semanticLabel: 'Loading your profile',
                    )
                  else
                    ErrorState(
                      title: '$message',
                      onRetry: widget.preview == null ? _load : null,
                      boxed: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return ProfileWizardPage(
      step: widget.step,
      record: record,
      submittedAt: _submittedAt,
      certified: _certified,
      onCertified: (bool value) => setState(() => _certified = value),
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoute.home.routeName);
        }
      },
      onPersonal: () =>
          context.goNamed(AppRoute.residentProfilePersonal.routeName),
      onHousehold: () =>
          context.goNamed(AppRoute.residentProfileAddress.routeName),
      onReview: () => context.goNamed(AppRoute.residentProfileReview.routeName),
      onEditPersonal: () =>
          context.goNamed(AppRoute.residentProfilePersonal.routeName),
      onEditHousehold: () =>
          context.goNamed(AppRoute.residentProfileAddress.routeName),
      onContinue: () => _continue(record),
    );
  }
}
