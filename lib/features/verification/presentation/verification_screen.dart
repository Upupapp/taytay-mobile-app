import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/biometric_consent_controller.dart';
import '../../../core/startup/platform_controller.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/biometric_consent_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/message_field.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/pill_button_row.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../profile/domain/profile_fields.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../domain/field_correction_note.dart';
import '../domain/verification_face.dart';
import '../domain/verification_id_type.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';
import 'manila_stamp.dart';
import 's3_chrome.dart';
import 'verification_controller.dart';
import 'verification_status_pages.dart';

/// Identity verification: the status the server reports, drawn as `03-01`
/// through `03-03`.
///
/// The face comes from [verificationFaceFor], which calls
/// [AccessLevel.fromVerificationTier]. An unknown tier is unverified. The
/// screen does not cache the profile it reads: the tier and any rejection
/// note live in this state and die with it.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({this.preferPending = false, super.key});

  /// Set when a `409` from `/me/verification-requests` opened this screen.
  ///
  /// It asks for the pending face until the server answers with verified or
  /// rejected. It does not change the session.
  final bool preferPending;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late final VerificationController _controller;

  /// The selfie's consent (D-209). No selfie is offered until it stands.
  late final BiometricConsentController _biometric;

  /// The resident chose "No, I'll verify in person" (D-210).
  bool _declined = false;
  bool _started = false;
  String? _tier;
  String? _reason;
  String _email = '';
  String _accountCreated = '';

  /// `verification_method` and `verification_decided_at` from `GET /me`.
  VerificationMethod? _method;
  DateTime? _decidedAt;
  bool _tierReady = false;
  String _idType = 'philid';
  CapturedDocument? _front;
  CapturedDocument? _back;
  CapturedDocument? _selfie;
  bool _frontSent = false;
  bool _backSent = false;
  bool _selfieSent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final dependencies = AppDependencies.of(context);
    _controller = VerificationController(
      repository: dependencies.verificationRepository,
      session: dependencies.session,
    )..addListener(_onChanged);
    _biometric = BiometricConsentController(
      platform: dependencies.platformRepository,
      consents: dependencies.accountControlsRepository,
      inPersonOffice: () =>
          dependencies.citizenApi.loadOffice(inPersonOfficeSlug),
    )..addListener(_onBiometric);
    _controller.refresh();
    _loadTier();
    unawaited(_biometric.load());
  }

  void _onBiometric() {
    if (_biometric.status is BiometricConsentUnavailable) {
      unawaited(_biometric.loadInPersonOffice());
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTier() async {
    final result = await AppDependencies.of(
      context,
    ).residentProfileRepository.loadOwnDetail();
    if (!mounted) return;
    if (result case Ok(:final value)) {
      final String? tier = value.verificationTier;
      if (tier != null && tier.isNotEmpty) {
        AppDependencies.of(context).session.applyVerificationTier(tier);
      }
      setState(() {
        _tier = tier;
        _reason = value.rejectionReason;
        _email = value.valueOf(ResidentProfileField.emailAddress) ?? '';
        _accountCreated = _stamp(value.createdAt);
        _method = value.verificationMethod;
        _decidedAt = value.verificationDecidedAt;
        _tierReady = true;
      });
      return;
    }
    setState(() => _tierReady = true);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _biometric
      ..removeListener(_onBiometric)
      ..dispose();
    super.dispose();
  }

  bool get _mayEdit => _controller.allowsEdit;

  bool get _mayStart => _controller.canStart;

  bool get _startReady => _front != null && _selfie != null;

  bool get _selfieKept =>
      (_controller.status?.selfieMediaId ?? '').isNotEmpty && !_selfieErased;

  /// The request's selfie was erased after a withdrawal (`selfie_erased_at`).
  bool get _selfieErased => _controller.status?.selfieErased ?? false;

  /// Whether a selfie slot may open: the consent stands, or can be asked for.
  bool get _selfieOffered =>
      _biometric.status is BiometricConsentGiven ||
      _biometric.status is BiometricConsentOwed;

  String get _submittedOn {
    final DateTime? at = _controller.status?.submittedAt;
    return at == null ? '' : formatManilaStamp(at);
  }

  String get _residentMessage => _controller.status?.residentGuidance ?? '';

  List<String> get _categories => <String>[
    for (final VerificationItemCategory category
        in _controller.status?.submittedCategories ??
            const <VerificationItemCategory>[])
      _noteLabel(category),
  ];

  String get _notice => _controller.failure?.residentMessage ?? '';

  VerificationFace get _face {
    final VerificationStatusDetail? status = _controller.status;
    // The profile tier wins when it is already a verification status.
    // `unverified` is "not started", so a pending or rejected request still
    // chooses the status screen. `approved` is the verified face.
    final String? request = status?.rawState;
    String? raw = (_tier != null && _tier!.isNotEmpty) ? _tier : request;
    // A request the office closed because it verified the account in person
    // says the account is verified, as an approved one does (D-210). The
    // profile tier still wins when it was read.
    if (raw == 'superseded') raw = 'verified';
    if ((raw == null || raw.isEmpty || raw == 'unverified') &&
        (request == 'pending' ||
            request == 'approved' ||
            request == 'rejected')) {
      raw = request;
    }
    // The KYC vocabulary says `approved` for the state this app already
    // treats as verified. The Node tier word is `verified`. Anything else
    // is left alone so an unknown string still fails closed.
    final String? tier = raw == 'approved' && (status?.isVerified ?? false)
        ? 'verified'
        : raw;
    final bool notes = status?.hasIssues ?? false;
    var face = verificationFaceFor(
      tier,
      fieldNotes: notes && tier == 'rejected',
    );
    if (widget.preferPending &&
        face != VerificationFace.verified &&
        face != VerificationFace.needsCorrection) {
      face = VerificationFace.pending;
    }
    return face;
  }

  List<FieldCorrectionNote> get _notes {
    final VerificationStatusDetail? status = _controller.status;
    if (status == null) return const <FieldCorrectionNote>[];
    return <FieldCorrectionNote>[
      for (final VerificationItemIssue issue in status.issues)
        FieldCorrectionNote(
          label: _noteLabel(issue.category),
          note: issue.instruction,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final face = _face;
    final VerificationStatusDetail? status = _controller.status;
    final String idLabel = idTypeLabel(status?.idType);
    // An in-person verification has no reviewed request: the date is the
    // account's own decision date.
    final String reviewed = _date(
      status?.isVerified == true ? status?.reviewedAt : _decidedAt,
    );
    final PlatformController platform = AppDependencies.of(context).platform;
    final Widget page = switch (face) {
      VerificationFace.verified => VerifiedStatusPage(
        onBack: () => _leave(context),
        onHome: () => context.goNamed(AppRoute.home.routeName),
        onProfile: () => context.goNamed(AppRoute.residentProfile.routeName),
        onDigitalId: () => context.goNamed(AppRoute.digitalId.routeName),
        onMessage: () => context.goNamed(AppRoute.messagesInbox.routeName),
        onRequestDocuments: () =>
            context.pushNamed(AppRoute.issuanceCatalogue.routeName),
        verifiedOn: reviewed,
        method: VerificationMethodCopy.of(_method),
        replaced: status?.supersededInPerson == true
            ? VerificationMethodCopy.replaced(
                erased: status?.selfieErased == true,
              )
            : '',
      ),
      // The review time is app config, read at startup; a later answer
      // redraws the sentence rather than leaving the bundled one (D-200).
      VerificationFace.pending => ListenableBuilder(
        listenable: platform,
        builder: (BuildContext context, Widget? _) => PendingStatusPage(
          onBack: () => _leave(context),
          accountCreated: _accountCreated,
          email: _email,
          idType: idLabel,
          submittedOn: _submittedOn,
          residentMessage: _residentMessage,
          categories: _categories,
          reviewTime: platform.bootstrap.verificationReviewTime,
          selfieNotice: _selfieErased ? _erasedNotice(pending: true) : null,
        ),
      ),
      VerificationFace.needsCorrection => NeedsCorrectionPage(
        onBack: () => _leave(context),
        // rejection_reason from GET /me. Staff `notes` on the verification
        // request are not a source of text a resident reads.
        reason: _reason ?? '',
        notes: _notes,
        idType: idLabel,
        reviewedOn: reviewed,
        submittedOn: _submittedOn,
        residentMessage: _residentMessage,
        categories: _categories,
        notice: _notice,
        frontValue: _slotLabel(
          file: _front,
          sent: _frontSent,
          empty: 'Upload new photo',
        ),
        backValue: _slotLabel(file: _back, sent: _backSent, empty: 'Add'),
        selfieKept: _selfieKept && _selfie == null,
        selfieValue: _slotLabel(
          file: _selfie,
          sent: _selfieSent,
          empty: _selfieKept
              ? 'Previous selfie kept'
              : _selfieErased
              ? VerificationSelfieCopy.erasedSlot
              : 'Take a selfie',
        ),
        selfieNotice: _selfieErased && _selfie == null
            ? _erasedNotice(pending: false)
            : _consentNotice(),
        onFront: _mayEdit ? () => _pick(VerificationPhotoSlot.front) : null,
        onBackPhoto: _mayEdit ? () => _pick(VerificationPhotoSlot.back) : null,
        onRetake: _mayEdit && _selfieOffered
            ? () => _pick(VerificationPhotoSlot.selfie)
            : null,
        onResubmit: _mayEdit && !_controller.submitting ? _resubmit : null,
        onCheckName: _checkName,
      ),
      VerificationFace.unverified => UnverifiedStatusPage(
        onBack: () => _leave(context),
        onStart: _mayStart && _startReady && !_controller.submitting
            ? _onStart
            : null,
        notice: _notice,
        below: _mayStart
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  NameCheckNote(onCheckName: _checkName),
                  const SizedBox(height: Spacing.section),
                  if (_consentNotice() case final Widget notice) ...<Widget>[
                    notice,
                    const SizedBox(height: Spacing.section),
                  ],
                  _startPhotos(),
                ],
              )
            : null,
      ),
    };
    if (!_tierReady && _controller.status == null && _controller.loading) {
      return _StatePage(
        onBack: () => _leave(context),
        child: const LoadingSkeleton(
          layout: SkeletonLayout.detail,
          count: 1,
          semanticLabel: 'Checking your verification status',
        ),
      );
    }
    // A failed check is not a tier. Showing "Not verified" here would invent
    // a status the server never sent.
    final String? tier = _tier;
    if (_controller.failure != null &&
        _controller.status == null &&
        (tier == null || tier.isEmpty)) {
      return _StatePage(
        onBack: () => _leave(context),
        child: ErrorState(
          title: 'Could not check your status',
          onRetry: () {
            _controller.refresh();
            _loadTier();
          },
          boxed: true,
        ),
      );
    }
    return page;
  }

  String _slotLabel({
    required CapturedDocument? file,
    required bool sent,
    required String empty,
  }) {
    if (file == null) return empty;
    return sent ? 'New photo sent' : 'Photo added';
  }

  Future<void> _pick(VerificationPhotoSlot slot) async {
    if (slot == VerificationPhotoSlot.selfie) {
      // The consent first, as its own act, before the camera opens: a selfie
      // the server would refuse is never taken (D-209).
      final BiometricConsentChoice choice = await ensureBiometricConsent(
        context,
        _biometric,
      );
      if (!mounted) return;
      if (choice == BiometricConsentChoice.declined) {
        setState(() => _declined = true);
        unawaited(_biometric.loadInPersonOffice());
        return;
      }
      if (choice != BiometricConsentChoice.agreed) return;
      if (_declined) setState(() => _declined = false);
    }
    if (!mounted) return;
    final DocumentPicker picker = AppDependencies.of(context).documentPicker;
    final DocumentSource preferred = slot == VerificationPhotoSlot.selfie
        ? DocumentSource.camera
        : DocumentSource.gallery;
    final DocumentSource source = picker.supports(preferred)
        ? preferred
        : DocumentSource.gallery;
    final CapturedDocument? picked = await picker.pick(
      source,
      UploadPolicy.fallback,
    );
    if (picked == null || !mounted) return;
    // A pending request whose selfie was erased takes its new one on the
    // request itself, as a rejected one does.
    final bool replacing =
        _face == VerificationFace.needsCorrection ||
        (_face == VerificationFace.pending && _selfieErased);
    final VerificationImagePart part = VerificationImagePart(
      bytes: picked.bytes,
      fileName: picked.fileName,
      mimeType: picked.mimeType,
    );
    if (replacing) {
      final bool ok = await _controller.replaceImage(
        front: slot == VerificationPhotoSlot.front ? part : null,
        back: slot == VerificationPhotoSlot.back ? part : null,
        selfie: slot == VerificationPhotoSlot.selfie ? part : null,
      );
      if (!mounted) return;
      if (!ok) {
        _afterRefusal();
        return;
      }
    }
    setState(() {
      switch (slot) {
        case VerificationPhotoSlot.front:
          _front = picked;
          _frontSent = replacing;
          break;
        case VerificationPhotoSlot.back:
          _back = picked;
          _backSent = replacing;
          break;
        case VerificationPhotoSlot.selfie:
          _selfie = picked;
          _selfieSent = replacing;
          break;
      }
    });
  }

  Future<void> _pickIdType() async {
    final String? chosen = await AppSheet.show<String>(
      context: context,
      title: 'Type of ID',
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final String wire in verificationIdTypes)
              ListTile(
                title: Text(idTypeLabel(wire)),
                onTap: () => Navigator.of(sheetContext).pop(wire),
              ),
          ],
        );
      },
    );
    if (chosen == null || !mounted) return;
    if (!verificationIdTypes.contains(chosen)) return;
    setState(() => _idType = chosen);
  }

  Future<void> _resubmit() async {
    final String? typed = await showResubmitMessageDialog(context);
    if (!mounted || typed == null) return;
    final bool ok = await _controller.resubmit(typed);
    if (!mounted || !ok) return;
    setState(() {
      _front = null;
      _back = null;
      _selfie = null;
      _frontSent = false;
      _backSent = false;
      _selfieSent = false;
    });
  }

  /// Edit profile, where the name is a field while no ID is pending or
  /// approved (D-195). The screen there reads the status itself.
  void _checkName() => context.goNamed(AppRoute.profileEdit.routeName);

  Future<void> _onStart() async {
    final CapturedDocument? front = _front;
    final CapturedDocument? selfie = _selfie;
    if (front == null || selfie == null) return;
    final CapturedDocument? back = _back;
    final bool ok = await _controller.startVerification(
      idType: _idType,
      front: VerificationImagePart(
        bytes: front.bytes,
        fileName: front.fileName,
        mimeType: front.mimeType,
      ),
      back: back == null
          ? null
          : VerificationImagePart(
              bytes: back.bytes,
              fileName: back.fileName,
              mimeType: back.mimeType,
            ),
      selfie: VerificationImagePart(
        bytes: selfie.bytes,
        fileName: selfie.fileName,
        mimeType: selfie.mimeType,
      ),
    );
    if (!mounted) return;
    if (!ok) {
      _afterRefusal();
      return;
    }
    setState(() {
      _front = null;
      _back = null;
      _selfie = null;
    });
  }

  /// A selfie the server refused for want of consent: what this screen knew
  /// about the consent is stale, so it is read again (D-209).
  void _afterRefusal() {
    final AppFailure? failure = _controller.failure;
    if (failure is ForbiddenFailure && failure.requiresBiometricConsent) {
      unawaited(_biometric.refusedForConsent());
    }
  }

  /// Why a selfie cannot be taken now, and the in-person way; null when the
  /// consent stands or can be asked for and was not declined.
  Widget? _consentNotice() {
    final BiometricConsentStatus status = _biometric.status;
    return switch (status) {
      BiometricConsentChecking() => const LoadingSkeleton(
        layout: SkeletonLayout.text,
        count: 1,
        semanticLabel: VerificationSelfieCopy.checking,
      ),
      BiometricConsentFailed() => SoftNote(
        key: verificationConsentFailedKey,
        tone: NoteTone.error,
        heading: BiometricConsentCopy.failedHeading,
        message: BiometricConsentCopy.failed,
        action: PillButtonRow(
          wrap: true,
          padding: EdgeInsets.zero,
          actions: <PillAction>[
            PillAction(
              label: 'Try again',
              primary: true,
              onPressed: () => unawaited(_biometric.load()),
            ),
          ],
        ),
      ),
      BiometricConsentUnavailable() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SoftNote(
            key: verificationSelfieUnavailableKey,
            tone: NoteTone.warning,
            heading: BiometricConsentCopy.unavailableHeading,
            message: BiometricConsentCopy.unavailable,
          ),
          const SizedBox(height: Spacing.md),
          InPersonVerificationNote(office: _biometric.inPersonOffice),
        ],
      ),
      BiometricConsentOwed() || BiometricConsentGiven() =>
        _declined
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SoftNote(
                    heading: BiometricConsentCopy.declinedHeading,
                    message: BiometricConsentCopy.declined,
                  ),
                  const SizedBox(height: Spacing.md),
                  InPersonVerificationNote(office: _biometric.inPersonOffice),
                ],
              )
            : null,
    };
  }

  /// The selfie was erased because the resident withdrew the consent. On a
  /// pending request staff cannot approve until a new one is sent (D-212).
  Widget _erasedNotice({required bool pending}) {
    final DateTime? at = _controller.status?.selfieErasedAt;
    final String on = at == null ? '' : ' on ${formatManilaDate(at)}';
    final bool canRetake = _mayEdit && _selfieOffered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SoftNote(
          key: verificationSelfieErasedKey,
          tone: NoteTone.warning,
          heading: VerificationSelfieCopy.erasedHeading,
          message: pending
              ? VerificationSelfieCopy.erasedPending(on)
              : VerificationSelfieCopy.erasedRejected(on),
          action: canRetake && pending
              ? PillButtonRow(
                  wrap: true,
                  padding: EdgeInsets.zero,
                  actions: <PillAction>[
                    PillAction(
                      label: VerificationSelfieCopy.retake,
                      primary: true,
                      buttonKey: verificationRetakeSelfieKey,
                      onPressed: _controller.submitting
                          ? null
                          : () => _pick(VerificationPhotoSlot.selfie),
                    ),
                  ],
                )
              : null,
        ),
        if (_consentNotice() case final Widget notice) ...<Widget>[
          const SizedBox(height: Spacing.md),
          notice,
        ],
      ],
    );
  }

  Widget _startPhotos() {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Send a new valid ID',
              style: AppTypography.sectionTitle.copyWith(
                color: BrandColors.ink,
              ),
            ),
          ),
          S3Field(
            key: const Key('verification-id-type'),
            label: 'Type of ID',
            asterisk: true,
            value: idTypeLabel(_idType),
            chevron: true,
            onTap: _pickIdType,
          ),
          S3Field(
            key: const Key('verification-id-front'),
            label: 'Front of ID',
            asterisk: true,
            value: _slotLabel(
              file: _front,
              sent: false,
              empty: 'Upload new photo',
            ),
            dashed: true,
            onTap: () => _pick(VerificationPhotoSlot.front),
            leading: const TaytayIcon(
              icon: TaytayIcons.plus,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.blue,
            ),
          ),
          S3Field(
            label: 'Back of ID (optional)',
            value: _slotLabel(file: _back, sent: false, empty: 'Add'),
            dashed: true,
            onTap: () => _pick(VerificationPhotoSlot.back),
            leading: const TaytayIcon(
              icon: TaytayIcons.plus,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.blue,
            ),
          ),
          S3Field(
            key: const Key('verification-selfie'),
            label: 'Selfie',
            value: _slotLabel(
              file: _selfie,
              sent: false,
              empty: 'Take a selfie',
            ),
            dashed: true,
            onTap: _selfieOffered
                ? () => _pick(VerificationPhotoSlot.selfie)
                : null,
            leading: const TaytayIcon(
              icon: TaytayIcons.plus,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _stamp(DateTime? instant) =>
      instant == null ? '' : formatManilaStamp(instant);

  String _date(DateTime? instant) =>
      instant == null ? '' : formatManilaDate(instant);

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.home.routeName);
    }
  }
}

enum VerificationPhotoSlot { front, back, selfie }

/// The slug of the office that verifies in person (D-210). Its name, address
/// and hours come from `GET /offices/{slug}`, never from the app.
const String inPersonOfficeSlug = 'mswdo';

/// The selfie notes on the verification screen.
const Key verificationSelfieErasedKey = Key('verification-selfie-erased');
const Key verificationSelfieUnavailableKey = Key(
  'verification-selfie-unavailable',
);
const Key verificationConsentFailedKey = Key('verification-consent-failed');
const Key verificationRetakeSelfieKey = Key('verification-retake-selfie');

/// How the account was verified, in words (D-210).
abstract final class VerificationMethodCopy {
  static const String inPerson = 'Verified in person at the Taytay LGU office.';
  static const String selfie = 'Verified with your valid ID and selfie.';

  static String of(VerificationMethod? method) => switch (method) {
    VerificationMethod.inPerson => inPerson,
    VerificationMethod.selfie => selfie,
    null => '',
  };

  /// A selfie request closed because the office verified the account in
  /// person (`superseded`).
  static String replaced({required bool erased}) => erased
      ? 'Replaced: you were verified in person at the office, so your selfie '
            'request was closed and the selfie you sent was erased.'
      : 'Replaced: you were verified in person at the office, so your selfie '
            'request was closed.';
}

/// What the verification screen says about the selfie (D-209, D-212).
abstract final class VerificationSelfieCopy {
  static const String checking = 'Checking the selfie consent';
  static const String erasedHeading = 'Your selfie was erased';
  static const String erasedSlot = 'Selfie erased: take a new one';
  static const String retake = 'Take a new selfie';

  static String erasedPending(String on) =>
      'You withdrew your selfie consent$on, so the selfie you sent was '
      'erased. Staff cannot approve this request until you send a new '
      'selfie, or you can verify in person instead.';

  static String erasedRejected(String on) =>
      'You withdrew your selfie consent$on, so the selfie you sent was '
      'erased. Send a new one with your ID, or verify in person instead.';
}

/// The status page while it has nothing to show yet, or could not read the
/// status: the same header over the soft page, with the state in the body.
class _StatePage extends StatelessWidget {
  const _StatePage({required this.child, required this.onBack});

  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          S3Header(
            title: 'Verification status',
            subtitle: 'Bayan ng Taytay · Rizal',
            onBack: onBack,
          ),
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[child],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for an optional note before a resubmission, in a centred dialog (a
/// decision; design rule: popups are centred). Resolves to the note, possibly
/// empty, or null when the resident closes the dialog.
Future<String?> showResubmitMessageDialog(BuildContext context) {
  return AppDialog.show<String>(
    context: context,
    title: 'Message to Taytay LGU',
    builder: (BuildContext _) => const _ResubmitMessageSheet(),
  );
}

/// Optional note on resubmit. The field lives in the dialog so it is disposed
/// with the dialog, the same way a directory message field owns its text.
class _ResubmitMessageSheet extends StatefulWidget {
  const _ResubmitMessageSheet();

  @override
  State<_ResubmitMessageSheet> createState() => _ResubmitMessageSheetState();
}

class _ResubmitMessageSheetState extends State<_ResubmitMessageSheet> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MessageField(
          controller: _field,
          fieldKey: const Key('verification-message-field'),
        ),
        // The dialog's actions, drawn here because Resubmit sends what is in
        // the field. Cancel sends nothing (the dialog resolves to null).
        AppDialogActions(
          primary: DialogButton(
            key: const Key('verification-resubmit-confirm'),
            label: 'Resubmit for verification',
            onPressed: () => Navigator.of(context).pop(_field.text),
          ),
          text: DialogButton(
            key: const Key('verification-resubmit-cancel'),
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

String _noteLabel(VerificationItemCategory category) => switch (category) {
  VerificationItemCategory.personalDetails => 'Your details',
  VerificationItemCategory.address => 'Address',
  VerificationItemCategory.contact => 'Contact details',
  VerificationItemCategory.identityDocument => 'ID photo',
  VerificationItemCategory.photo => 'Photo of you',
  VerificationItemCategory.other => 'Details',
};
