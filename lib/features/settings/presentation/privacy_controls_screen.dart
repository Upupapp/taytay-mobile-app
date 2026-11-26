import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/request_context.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/settings_copy.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/session/biometric_consent_controller.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/pill_button_row.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/soft_page.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../domain/account_controls.dart';

/// What a resident agreed to, and what they may ask the office to change.
///
/// ---
///
/// **Nothing appears that the backend did not say is available.** Acceptance 3
/// of TAB 24 is that no unsupported legal promise is invented in the UI, and on
/// a government app that is stricter than it sounds: a "Delete my account"
/// button is a statement about what the LGU will do with a civil record, and
/// retention is set by law and municipal rule rather than by a client. Showing
/// the button and hoping the server refuses would be this app making a promise
/// on the municipality's behalf.
///
/// So `AccountControls` defaults to nothing, the planned backend returns exactly
/// that, and this screen says plainly that the paths are not switched on yet.
class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen>
    with LiveRefresh<PrivacyControlsScreen> {
  /// The selfie's consent, read from the server (D-209). Created with the
  /// first dependencies.
  BiometricConsentController? _biometric;
  bool _loading = true;
  AccountControls _controls = AccountControls.none;
  List<ConsentRecord>? _consents;
  AppFailure? _consentsFailure;
  String? _notice;

  /// A withdrawal or an agreement is on its way. A re-read for a change
  /// waits for it, and one that started before it is not applied (D-218).
  bool _acting = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_biometric == null) {
      final AppDependencies dependencies = AppDependencies.of(context);
      _biometric = BiometricConsentController(
        platform: dependencies.platformRepository,
        consents: dependencies.accountControlsRepository,
      )..addListener(_onBiometric);
      unawaited(_biometric?.load());
      // A consent recorded or withdrawn elsewhere (at the office, or on
      // another phone) shows without a pull (D-218, D-221).
      listenLive(dependencies.live, const <String>{
        LiveTopics.consents,
      }, () => unawaited(_reloadQuietly()));
    }
    if (_loading) _load();
  }

  /// Re-reads the consent list for a change: no loading state, and a read
  /// that fails keeps the list and says nothing. The selfie section keeps
  /// its own read, whose reload shows a skeleton, so it is not repeated here.
  Future<void> _reloadQuietly() async {
    if (_loading || _acting || _consents == null) return;
    final int generation = _generation;
    final Result<List<ConsentRecord>> consents = await AppDependencies.of(
      context,
    ).accountControlsRepository.listConsents();
    if (!mounted || generation != _generation || _loading || _acting) return;
    if (consents case Ok(:final value)) setState(() => _consents = value);
  }

  void _onBiometric() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _biometric
      ?..removeListener(_onBiometric)
      ..dispose();
    super.dispose();
  }

  /// Withdraws the selfie consent after a confirmation that says what it
  /// does. The effects are also said on the page, before the button (D-211).
  Future<void> _withdrawBiometric(BiometricConsentController controller) async {
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.of(context).sharedBiometricWithdrawTitle,
      message: AppStrings.of(context).sharedBiometricWithdrawEffects,
      confirmLabel: AppStrings.of(context).sharedBiometricWithdrawConfirm,
      cancelLabel: AppStrings.of(context).sharedBiometricWithdrawCancel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final bool done = await controller.withdraw();
    if (!mounted) return;
    final AppFailure? failure = controller.recordFailure;
    final AppStrings strings = AppStrings.of(context);
    setState(() {
      _notice = done
          ? strings.settingsBiometricWithdrawn
          : (failure?.outcomeUnknown ?? false)
          ? strings.settingsWithdrawalUnconfirmed
          : strings.settingsWithdrawalNotRecorded;
    });
    if (done) unawaited(_load());
  }

  /// The selfie consent, where it stands, and the way to withdraw it.
  Widget _biometricSection(TextStyle body) {
    final BiometricConsentController? controller = _biometric;
    if (controller == null) return const SizedBox.shrink();
    final BiometricConsentStatus status = controller.status;
    final AppStrings strings = AppStrings.of(context);
    return switch (status) {
      BiometricConsentChecking() => LoadingSkeleton(
        layout: SkeletonLayout.text,
        count: 2,
        semanticLabel: strings.settingsCheckingSelfieConsent,
      ),
      BiometricConsentFailed() => SoftNote(
        key: privacyBiometricFailedKey,
        tone: NoteTone.error,
        heading: strings.sharedBiometricFailedHeading,
        message: strings.settingsSelfieConsentUnreadable,
        action: PillButtonRow(
          wrap: true,
          padding: EdgeInsets.zero,
          actions: <PillAction>[
            PillAction(
              label: strings.actionTryAgain,
              primary: true,
              onPressed: () => unawaited(controller.load()),
            ),
          ],
        ),
      ),
      BiometricConsentUnavailable() => Text(
        strings.settingsSelfieConsentUnpublished,
        key: privacyBiometricUnavailableKey,
        style: body,
      ),
      BiometricConsentOwed() => Text(
        strings.settingsSelfieConsentOwed,
        key: privacyBiometricOwedKey,
        style: body,
      ),
      BiometricConsentGiven(
        :final String version,
        :final DateTime? acceptedAt,
      ) =>
        SoftCard(
          key: privacyBiometricGivenKey,
          filled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                acceptedAt == null
                    ? strings.settingsSelfieConsentGiven(version)
                    : strings.settingsSelfieConsentGivenOn(
                        ManilaTime.formatDate(
                          acceptedAt,
                          languageCode: Localizations.localeOf(
                            context,
                          ).languageCode,
                        ),
                        version,
                      ),
                style: body,
              ),
              const SizedBox(height: Spacing.md),
              // What withdrawing does, before the button (NPC Circular
              // 2023-04: consequences explained).
              SoftNote(
                key: privacyBiometricEffectsKey,
                tone: NoteTone.warning,
                heading: strings.settingsWhatWithdrawingDoes,
                message: strings.sharedBiometricWithdrawEffects,
                live: false,
              ),
              const SizedBox(height: Spacing.md),
              AppButton(
                key: privacyBiometricWithdrawKey,
                label: strings.sharedBiometricWithdrawButton,
                variant: AppButtonVariant.danger,
                loading: controller.isRecording,
                onPressed: controller.isRecording
                    ? null
                    : () => _withdrawBiometric(controller),
              ),
            ],
          ),
        ),
    };
  }

  void _retry() {
    setState(() {
      _loading = true;
      _consentsFailure = null;
    });
    _load();
  }

  Future<void> _load() async {
    _generation++;
    final repository = AppDependencies.of(context).accountControlsRepository;

    final controls = await repository.loadControls();
    final consents = await repository.listConsents();
    if (!mounted) return;

    setState(() {
      _loading = false;
      controls.fold(
        onOk: (value) => _controls = value,
        onErr: (_) => _controls = AccountControls.none,
      );
      consents.fold(
        onOk: (value) {
          _consents = value;
          _consentsFailure = null;
        },
        onErr: (failure) {
          _consents = null;
          _consentsFailure = failure;
        },
      );
    });
  }

  Future<void> _withdraw(ConsentRecord consent) async {
    if (!consent.isWithdrawable || consent.key.isEmpty) return;
    final AppStrings strings = AppStrings.of(context);
    final confirmed = await ConfirmSheet.show(
      context: context,
      title: strings.settingsWithdrawConsentTitle,
      consequence: strings.settingsWithdrawConsentConsequence,
      detail: consentRecordStatement(strings, consent),
      confirmLabel: strings.settingsWithdrawIt,
      cancelLabel: strings.settingsLeaveInPlace,
    );
    if (!confirmed || !mounted) return;

    final repository = AppDependencies.of(context).accountControlsRepository;
    _acting = true;
    _generation++;
    final result = await repository.withdrawConsent(
      key: consent.key,
      // Withdrawing twice through a dropped connection should record one
      // withdrawal, not two entries in a legal history.
      idempotencyKey: generateRequestId(),
      // The text this row is for, and only it (D-208).
      kind: consent.kind,
    );
    _acting = false;
    if (!mounted) return;

    result.fold(
      onOk: (_) {
        setState(() => _notice = strings.settingsWithdrawalRecorded);
        _load();
      },
      // A withdrawal of the same version returns the same row, so trying
      // again is safe. After a timeout the office may already have it, and
      // "nothing has changed" would be a guess.
      onErr: (AppFailure failure) => setState(
        () => _notice = failure.outcomeUnknown
            ? strings.settingsWithdrawalUnconfirmed
            : strings.settingsWithdrawalNotRecorded,
      ),
    );
  }

  Future<void> _accept(ConsentRecord consent) async {
    if (!consent.isWithdrawable || consent.key.isEmpty) return;
    final AppStrings strings = AppStrings.of(context);
    final repository = AppDependencies.of(context).accountControlsRepository;
    _acting = true;
    _generation++;
    final result = await repository.acceptConsent(
      version: consent.key,
      kind: consent.kind,
    );
    _acting = false;
    if (!mounted) return;
    result.fold(
      onOk: (_) {
        setState(() => _notice = strings.settingsConsentRecordedAgain);
        _load();
      },
      // Recording a version is idempotent on the server, as above.
      onErr: (AppFailure failure) => setState(
        () => _notice = failure.outcomeUnknown
            ? strings.settingsConsentUnconfirmed
            : strings.settingsConsentNotRecorded,
      ),
    );
  }

  /// Closes the account (`POST /me/close`), after a confirmation that says
  /// what closing does. The same is said on the page, before the button, and
  /// after it in the notice (D-235).
  ///
  /// **A close, not a request.** The API closes the account at once; nobody
  /// reviews it and nobody calls. The words used to say "the office will
  /// contact you", which was untrue.
  Future<void> _closeAccount() async {
    final AppStrings strings = AppStrings.of(context);
    final confirmed = await ConfirmSheet.show(
      context: context,
      title: strings.settingsCloseConfirmTitle,
      consequence: strings.settingsCloseConfirm,
      detail: _controls.deletionPolicyNote,
      confirmLabel: strings.settingsCloseAction,
      cancelLabel: strings.gateSheetNotNow,
    );
    if (!confirmed || !mounted) return;

    final repository = AppDependencies.of(context).accountControlsRepository;
    final result = await repository.requestAccountClosure(
      permanent: _controls.canRequestDeletion,
      reason: '',
      idempotencyKey: generateRequestId(),
    );
    if (!mounted) return;

    setState(() {
      _notice = switch (result) {
        Ok() => strings.settingsClosed,
        // A second close is refused with 409: an earlier try, whose answer
        // was lost, already closed it.
        Err(failure: ConflictFailure()) => strings.settingsCloseAlreadyClosed,
        Err(:final failure) when failure.outcomeUnknown =>
          strings.settingsCloseNotConfirmed,
        Err() => strings.settingsCloseNotClosed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return AuthFormPage(
      title: strings.settingsConsentsTitle,
      child: CapabilityGate(
        capability: ResidentCapability.manageAccount,
        child: _loading
            ? LoadingSkeleton(
                layout: SkeletonLayout.cards,
                count: 2,
                semanticLabel: strings.settingsLoadingConsents,
              )
            : _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final consents = _consents;
    final notice = _notice;
    final TextStyle body = AppTypography.bodyStyle.copyWith(
      color: BrandColors.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const OfflineBanner(),
        if (notice != null) ...<Widget>[
          SoftNote(title: 'Taytay LGU. ', message: notice),
          const SizedBox(height: Spacing.lg),
        ],

        SettingsSectionTitle(strings.settingsSelfieConsent),
        _biometricSection(body),
        const SizedBox(height: Spacing.xl),

        SettingsSectionTitle(strings.settingsSectionAgreed),

        // `GET me/consents` is served: a failed read is said as itself, with
        // Try again, never as history the LGU has "not switched on"
        // (DESIGN_SYSTEM.md §5).
        if (_consentsFailure case final AppFailure failure)
          FailureView(
            failure: failure,
            environment: AppDependencies.of(context).config.environment,
            onRetry: _retry,
          )
        else if (consents == null || consents.isEmpty)
          Text(strings.settingsNoConsents, style: body)
        else
          for (final consent in consents)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: _ConsentCard(
                consent: consent,
                canWithdraw: _controls.canWithdrawConsent,
                onWithdraw: () => _withdraw(consent),
                onAccept: () => _accept(consent),
              ),
            ),

        const SizedBox(height: Spacing.xl),
        SettingsSectionTitle(strings.settingsSectionAskingChanges),

        if (!_controls.hasAnyAccountRequest)
          Text(strings.settingsRequestsNotOn, style: body)
        else ...<Widget>[
          if (_controls.canRequestDataCorrection) ...<Widget>[
            AppButton(
              label: strings.settingsAskCorrection,
              variant: AppButtonVariant.secondary,
              onPressed: () =>
                  setState(() => _notice = strings.settingsCorrectionNotice),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          // Both switches lead to the one thing the API does: it closes the
          // account at once (`POST /me/close`). One button, with what it does
          // said before it, last and styled apart from the rest (D-235).
          if (_controls.canRequestDeactivation ||
              _controls.canRequestDeletion) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              strings.settingsCloseEffects,
              key: privacyCloseEffectsKey,
              style: body,
            ),
            const SizedBox(height: Spacing.md),
            AppButton(
              label: strings.settingsCloseAction,
              variant: AppButtonVariant.danger,
              onPressed: _closeAccount,
            ),
          ],
        ],

        if (_controls.requiresReauthentication) ...<Widget>[
          const SizedBox(height: Spacing.lg),
          SoftNote(
            title: strings.settingsReauthTitle,
            message: strings.settingsReauthBody,
          ),
        ],
      ],
    );
  }
}

const Key privacyCloseEffectsKey = Key('privacy-close-effects');
const Key privacyBiometricGivenKey = Key('privacy-biometric-given');
const Key privacyBiometricOwedKey = Key('privacy-biometric-owed');
const Key privacyBiometricUnavailableKey = Key('privacy-biometric-unavailable');
const Key privacyBiometricFailedKey = Key('privacy-biometric-failed');
const Key privacyBiometricEffectsKey = Key('privacy-biometric-effects');
const Key privacyBiometricWithdrawKey = Key('privacy-biometric-withdraw');

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.consent,
    required this.canWithdraw,
    required this.onWithdraw,
    required this.onAccept,
  });

  final ConsentRecord consent;
  final bool canWithdraw;
  final VoidCallback onWithdraw;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final String? withheld = consent.withheldReason;
    final DateTime? granted = consent.grantedAt;
    final DateTime? withdrawn = consent.withdrawnAt;
    final AppStrings strings = AppStrings.of(context);
    final String dates = <String>[
      if (granted != null)
        strings.settingsConsentAgreedOn(
          ManilaTime.formatDate(granted, languageCode: strings.localeName),
        ),
      if (withdrawn != null)
        strings.settingsConsentWithdrawnOn(
          ManilaTime.formatDate(withdrawn, languageCode: strings.localeName),
        ),
    ].join(' · ');

    return SoftCard(
      filled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Semantics(
                label: consent.isActive
                    ? strings.settingsConsentInForce
                    : strings.settingsConsentWithdrawn,
                child: SettingsIcon(
                  icon: consent.isActive
                      ? TaytayIcons.check
                      : TaytayIcons.clock,
                  tone: consent.isActive
                      ? SettingsTone.green
                      : SettingsTone.gold,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  consentRecordLabel(strings, consent),
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // The office's own sentence, never a paraphrase. A sentence the
          // app composed for the row's kind is said in the resident's
          // language.
          Text(
            consentRecordStatement(strings, consent),
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
          ),
          if (dates.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              dates,
              style: AppTypography.small.copyWith(color: BrandColors.muted),
            ),
          ],

          // A withdrawn consent keeps its row: the record is the point, and
          // removing it would erase the evidence it exists to provide. The
          // selfie consent is withdrawn from its own section, where what that
          // does is said first, and given again only before a selfie, with
          // its text (D-209, D-211).
          if (consent.kind != ConsentKind.biometric &&
              consent.isActive &&
              canWithdraw &&
              consent.isWithdrawable &&
              consent.key.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            AppButton(
              label: strings.settingsWithdrawConsent,
              variant: AppButtonVariant.text,
              onPressed: onWithdraw,
            ),
          ] else if (consent.kind != ConsentKind.biometric &&
              !consent.isActive &&
              consent.isWithdrawable &&
              consent.key.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            AppButton(
              label: strings.settingsAcceptAgain,
              variant: AppButtonVariant.primary,
              onPressed: onAccept,
            ),
          ] else if (consent.isActive && withheld != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              withheld,
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Help, and where to go in person.
///
/// **Public, and fixed text.** It collects nothing and looks nothing up, so a
/// guest — the person most likely to need it — reads it without an account.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return SoftPage(
      title: strings.settingsHelp,
      children: <Widget>[
        SettingsSectionTitle(strings.settingsHelpGettingHelp),
        Text(
          strings.settingsHelpIntro,
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
        ),
        const SizedBox(height: Spacing.lg),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            children: <Widget>[
              _Faq(
                question: strings.settingsFaqAccountQuestion,
                answer: strings.settingsFaqAccountAnswer,
              ),
              _Faq(
                question: strings.settingsFaqVerifyQuestion,
                answer: strings.settingsFaqVerifyAnswer,
              ),
              _Faq(
                question: strings.settingsFaqDurationQuestion,
                answer: strings.settingsFaqDurationAnswer,
              ),
              _Faq(
                question: strings.settingsFaqRecordQuestion,
                answer: strings.settingsFaqRecordAnswer,
              ),
              _Faq(
                question: strings.settingsFaqLostPhoneQuestion,
                answer: strings.settingsFaqLostPhoneAnswer,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        // No invented phone number, address or opening hours. Publishing an
        // office's contact details this app cannot verify is how a resident
        // travels to a building that closed.
        SoftNote(
          title: strings.settingsHelpContactTitle,
          message: strings.settingsHelpContactBody,
        ),
      ],
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: BrandColors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: Spacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: BrandColors.blue,
        collapsedIconColor: BrandColors.chevron,
        title: Text(
          question,
          style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
        ),
        children: <Widget>[
          Text(
            answer,
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
          ),
        ],
      ),
    );
  }
}
