import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/request_context.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/session/biometric_consent_controller.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/biometric_consent_dialog.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/confirm_sheet.dart';
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

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  /// The selfie's consent, read from the server (D-209). Created with the
  /// first dependencies.
  BiometricConsentController? _biometric;
  bool _loading = true;
  AccountControls _controls = AccountControls.none;
  List<ConsentRecord>? _consents;
  AppFailure? _consentsFailure;
  String? _notice;

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
    }
    if (_loading) _load();
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
      title: BiometricConsentCopy.withdrawTitle,
      message: BiometricConsentCopy.withdrawEffects,
      confirmLabel: BiometricConsentCopy.withdrawConfirm,
      cancelLabel: BiometricConsentCopy.withdrawCancel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final bool done = await controller.withdraw();
    if (!mounted) return;
    final AppFailure? failure = controller.recordFailure;
    setState(() {
      _notice = done
          ? 'Taytay LGU has recorded your withdrawal, and your selfies were '
                'erased.'
          : (failure?.outcomeUnknown ?? false)
          ? 'We could not confirm that your withdrawal was recorded. Trying '
                'again is safe: it is recorded only once.'
          : 'That withdrawal was not recorded. Nothing has changed, and you '
                'can try again.';
    });
    if (done) unawaited(_load());
  }

  /// The selfie consent, where it stands, and the way to withdraw it.
  Widget _biometricSection(TextStyle body) {
    final BiometricConsentController? controller = _biometric;
    if (controller == null) return const SizedBox.shrink();
    final BiometricConsentStatus status = controller.status;
    return switch (status) {
      BiometricConsentChecking() => const LoadingSkeleton(
        layout: SkeletonLayout.text,
        count: 2,
        semanticLabel: 'Checking the selfie consent',
      ),
      BiometricConsentFailed() => SoftNote(
        key: privacyBiometricFailedKey,
        tone: NoteTone.error,
        heading: BiometricConsentCopy.failedHeading,
        message:
            'Where your selfie consent stands could not be read. Check your '
            'connection and try again.',
        action: PillButtonRow(
          wrap: true,
          padding: EdgeInsets.zero,
          actions: <PillAction>[
            PillAction(
              label: 'Try again',
              primary: true,
              onPressed: () => unawaited(controller.load()),
            ),
          ],
        ),
      ),
      BiometricConsentUnavailable() => Text(
        'Taytay LGU has not published a selfie consent yet, so the app takes '
        'no selfie and holds no consent for one.',
        key: privacyBiometricUnavailableKey,
        style: body,
      ),
      BiometricConsentOwed() => Text(
        'You have not agreed to the selfie consent. The app asks before it '
        'takes any selfie, and you can verify in person instead.',
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
                    ? 'You agreed that Taytay LGU may take and use your '
                          'selfie (version $version).'
                    : 'You agreed on ${ManilaTime.formatDate(acceptedAt)} '
                          'that Taytay LGU may take and use your selfie '
                          '(version $version).',
                style: body,
              ),
              const SizedBox(height: Spacing.md),
              // What withdrawing does, before the button (NPC Circular
              // 2023-04: consequences explained).
              const SoftNote(
                key: privacyBiometricEffectsKey,
                tone: NoteTone.warning,
                heading: 'What withdrawing does',
                message: BiometricConsentCopy.withdrawEffects,
                live: false,
              ),
              const SizedBox(height: Spacing.md),
              AppButton(
                key: privacyBiometricWithdrawKey,
                label: BiometricConsentCopy.withdrawButton,
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

  Future<void> _load() async {
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
    final confirmed = await ConfirmSheet.show(
      context: context,
      title: 'Withdraw this consent?',
      consequence:
          'Taytay LGU will stop relying on this consent from the moment it is '
          'recorded. Anything already done under it stays as it is — a '
          'withdrawal is not backdated.',
      detail: consent.statement,
      confirmLabel: 'Withdraw it',
      cancelLabel: 'Leave it in place',
    );
    if (!confirmed || !mounted) return;

    final repository = AppDependencies.of(context).accountControlsRepository;
    final result = await repository.withdrawConsent(
      key: consent.key,
      // Withdrawing twice through a dropped connection should record one
      // withdrawal, not two entries in a legal history.
      idempotencyKey: generateRequestId(),
      // The text this row is for, and only it (D-208).
      kind: consent.kind,
    );
    if (!mounted) return;

    result.fold(
      onOk: (_) {
        setState(() => _notice = 'Taytay LGU has recorded your withdrawal.');
        _load();
      },
      // A withdrawal of the same version returns the same row, so trying
      // again is safe. After a timeout the office may already have it, and
      // "nothing has changed" would be a guess.
      onErr: (AppFailure failure) => setState(
        () => _notice = failure.outcomeUnknown
            ? 'We could not confirm that your withdrawal was recorded. Trying '
                  'again is safe: it is recorded only once.'
            : 'That withdrawal was not recorded. Nothing has changed, and you '
                  'can try again.',
      ),
    );
  }

  Future<void> _accept(ConsentRecord consent) async {
    if (!consent.isWithdrawable || consent.key.isEmpty) return;
    final repository = AppDependencies.of(context).accountControlsRepository;
    final result = await repository.acceptConsent(
      version: consent.key,
      kind: consent.kind,
    );
    if (!mounted) return;
    result.fold(
      onOk: (_) {
        setState(() => _notice = 'Taytay LGU has recorded this consent again.');
        _load();
      },
      // Recording a version is idempotent on the server, as above.
      onErr: (AppFailure failure) => setState(
        () => _notice = failure.outcomeUnknown
            ? 'We could not confirm that your consent was recorded. Trying '
                  'again is safe: it is recorded only once.'
            : 'That consent was not recorded. Nothing has changed, and you '
                  'can try again.',
      ),
    );
  }

  Future<void> _requestClosure({required bool permanent}) async {
    final confirmed = await ConfirmSheet.show(
      context: context,
      title: permanent
          ? 'Ask Taytay LGU to erase your account?'
          : 'Ask Taytay LGU to switch off your account?',
      consequence: permanent
          ? 'This asks the office to erase your account. It is a request, not '
                'an instant deletion — Taytay LGU decides what it can erase and '
                'what it must keep by law.'
          : 'This asks the office to switch your account off. Your resident '
                'record with Taytay LGU stays as it is.',
      detail: _controls.deletionPolicyNote,
      confirmLabel: permanent ? 'Send the request' : 'Send the request',
      cancelLabel: 'Not now',
    );
    if (!confirmed || !mounted) return;

    final repository = AppDependencies.of(context).accountControlsRepository;
    final result = await repository.requestAccountClosure(
      permanent: permanent,
      reason: '',
      idempotencyKey: generateRequestId(),
    );
    if (!mounted) return;

    setState(() {
      _notice = result.isOk
          ? 'Taytay LGU has your request. The office will contact you.'
          : 'That request was not sent, so nothing has been asked for. You can '
                'try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormPage(
      title: 'Consents and account requests',
      child: CapabilityGate(
        capability: ResidentCapability.manageAccount,
        child: _loading
            ? const LoadingSkeleton(
                layout: SkeletonLayout.cards,
                count: 2,
                semanticLabel: 'Loading your consents',
              )
            : _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
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

        const SettingsSectionTitle('Selfie consent'),
        _biometricSection(body),
        const SizedBox(height: Spacing.xl),

        const SettingsSectionTitle('What you agreed to'),

        if (_consentsFailure != null)
          const SoftNote(
            title: 'Not available yet. ',
            message:
                'Taytay LGU has not switched on consent history in this app '
                'yet. The municipal hall holds the record and can show it to '
                'you.',
          )
        else if (consents == null || consents.isEmpty)
          Text('Taytay LGU has no consents recorded for you.', style: body)
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
        const SettingsSectionTitle('Asking Taytay LGU for changes'),

        if (!_controls.hasAnyAccountRequest)
          Text(
            'These requests are not switched on in this app yet. The municipal '
            'hall can take them in person, and your barangay hall can tell you '
            'where to go.',
            style: body,
          )
        else ...<Widget>[
          if (_controls.canRequestDataCorrection) ...<Widget>[
            AppButton(
              label: 'Ask for a correction',
              variant: AppButtonVariant.secondary,
              onPressed: () => setState(
                () => _notice =
                    'Corrections to your resident record are made by Taytay '
                    'LGU. Use the correction path on your household or profile '
                    'screen so the office knows which record you mean.',
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          if (_controls.canRequestDeactivation) ...<Widget>[
            AppButton(
              label: 'Ask to switch off my account',
              variant: AppButtonVariant.secondary,
              onPressed: () => _requestClosure(permanent: false),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          // Erasure last, and styled apart from the rest.
          if (_controls.canRequestDeletion)
            AppButton(
              label: 'Ask to erase my account',
              variant: AppButtonVariant.danger,
              onPressed: () => _requestClosure(permanent: true),
            ),
        ],

        if (_controls.requiresReauthentication) ...<Widget>[
          const SizedBox(height: Spacing.lg),
          const SoftNote(
            title: 'You may be asked to sign in again. ',
            message:
                'Taytay LGU asks residents to confirm who they are before '
                'changes like these.',
          ),
        ],
      ],
    );
  }
}

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
    final String dates = <String>[
      if (granted != null) 'Agreed ${ManilaTime.formatDate(granted)}',
      if (withdrawn != null) 'Withdrawn ${ManilaTime.formatDate(withdrawn)}',
    ].join(' · ');

    return SoftCard(
      filled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Semantics(
                label: consent.isActive ? 'In force' : 'Withdrawn',
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
                  consent.label,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // The office's own sentence, never a paraphrase.
          Text(
            consent.statement,
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
              label: 'Withdraw this consent',
              variant: AppButtonVariant.text,
              onPressed: onWithdraw,
            ),
          ] else if (consent.kind != ConsentKind.biometric &&
              !consent.isActive &&
              consent.isWithdrawable &&
              consent.key.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            AppButton(
              label: 'Accept again',
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
    return SoftPage(
      title: 'Help',
      children: <Widget>[
        const SettingsSectionTitle('Getting help'),
        Text(
          'Everything in this app is also handled at the Taytay municipal '
          'hall and at your barangay hall. If something here will not work, '
          'going in person is never the wrong answer.',
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
        ),
        const SizedBox(height: Spacing.lg),
        const SoftCard(
          padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            children: <Widget>[
              _Faq(
                question: 'Do I need an account to use this app?',
                answer:
                    'No. Announcements, events and the list of municipal '
                    'services are open to everyone. You only need an account '
                    'for things about you — your applications, your documents, '
                    'your ID.',
              ),
              _Faq(
                question: 'Why does it ask me to verify my identity?',
                answer:
                    'Some services act on your resident record with Taytay '
                    'LGU, so the office has to know it is you. Verifying is '
                    'done once and unlocks those services.',
              ),
              _Faq(
                question: 'How long will my application take?',
                answer:
                    'Taytay LGU decides that, and it depends on the service and '
                    'the documents. This app shows you where your application '
                    'is and what is needed next, but it cannot promise a date.',
              ),
              _Faq(
                question: 'Something in my record is wrong.',
                answer:
                    'You can report it from your profile or household screen. '
                    'The office checks and corrects it — the app never changes '
                    'your record directly.',
              ),
              _Faq(
                question: 'I lost my phone.',
                answer:
                    'Sign in on your new phone. If you think somebody else is '
                    'using your account, tell the municipal hall, and sign out '
                    'other devices from the sign-in and security screen.',
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        // No invented phone number, address or opening hours. Publishing an
        // office's contact details this app cannot verify is how a resident
        // travels to a building that closed.
        const SoftNote(
          title: 'Contacting Taytay LGU. ',
          message:
              'Use the contact details published on the service, programme '
              'or event you are asking about — those come from the office '
              'running it. Your barangay hall can always point you to the '
              'right desk.',
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
