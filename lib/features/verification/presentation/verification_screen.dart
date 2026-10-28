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
import '../../../shared/widgets/taytay_icon.dart';
import '../../profile/domain/profile_fields.dart';
import '../domain/field_correction_note.dart';
import '../domain/verification_face.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';
import 'manila_stamp.dart';
import 's3_chrome.dart';
import 'verification_controller.dart';
import 'verification_status_pages.dart';

/// Stored with `POST .../corrections`. It is the sentence the resident sends
/// by pressing Resubmit, not a staff note.
const String verificationResubmitMessage =
    'Please review my verification again.';

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
  bool _started = false;
  String? _tier;
  String? _reason;
  String _email = '';
  String _accountCreated = '';
  bool _tierReady = false;
  bool _collectingStart = false;
  bool _needPhotos = false;
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
    _controller.refresh();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final result = await AppDependencies.of(context).residentProfileRepository
        .loadOwnDetail();
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
    super.dispose();
  }

  bool get _mayEdit {
    final VerificationStatusDetail? status = _controller.status;
    if (status == null) return _face == VerificationFace.unverified;
    return _controller.allowsEdit;
  }

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

  String get _notice {
    if (_needPhotos) {
      return 'Add a photo of the front of your ID and a selfie.';
    }
    return _controller.failure?.residentMessage ?? '';
  }

  VerificationFace get _face {
    final VerificationStatusDetail? status = _controller.status;
    // The profile tier wins when it is already a verification status.
    // `unverified` is "not started", so a pending or rejected request still
    // chooses the status screen. `approved` is the verified face.
    final String? request = status?.rawState;
    String? raw = (_tier != null && _tier!.isNotEmpty) ? _tier : request;
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
    final String reviewed = _date(status?.reviewedAt);
    final Widget page = switch (face) {
      VerificationFace.verified => VerifiedStatusPage(
        onBack: () => _leave(context),
        onHome: () => context.goNamed(AppRoute.home.routeName),
        onProfile: () => context.goNamed(AppRoute.residentProfile.routeName),
        onDigitalId: () => context.goNamed(AppRoute.digitalId.routeName),
        onMessage: () => context.goNamed(AppRoute.messagesInbox.routeName),
        verifiedOn: reviewed,
      ),
      VerificationFace.pending => PendingStatusPage(
        onBack: () => _leave(context),
        accountCreated: _accountCreated,
        email: _email,
        idType: idLabel,
        submittedOn: _submittedOn,
        residentMessage: _residentMessage,
        categories: _categories,
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
        selfieValue: _slotLabel(
          file: _selfie,
          sent: _selfieSent,
          empty: 'Previous selfie kept',
        ),
        onFront: _mayEdit ? () => _pick(VerificationPhotoSlot.front) : null,
        onBackPhoto: _mayEdit ? () => _pick(VerificationPhotoSlot.back) : null,
        onRetake: _mayEdit ? () => _pick(VerificationPhotoSlot.selfie) : null,
        onResubmit: _mayEdit && !_controller.submitting ? _resubmit : null,
      ),
      VerificationFace.unverified => UnverifiedStatusPage(
        onBack: () => _leave(context),
        onStart: _mayEdit && !_controller.submitting ? _onStart : null,
        notice: _notice,
        below: _collectingStart && _mayEdit ? _startPhotos(idLabel) : null,
      ),
    };
    if (!_tierReady && _controller.status == null && _controller.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F5FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // A failed check is not a tier. Showing "Not verified" here would invent
    // a status the server never sent.
    if (_controller.failure != null &&
        _controller.status == null &&
        (_tier == null || _tier!.isEmpty)) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F5FA),
        body: Column(
          children: <Widget>[
            S3Header(
              title: 'Verification status',
              subtitle: 'Bayan ng Taytay · Rizal',
            ),
            Expanded(child: Center(child: Text('Could not check your status'))),
          ],
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
    final bool replacing = _face == VerificationFace.needsCorrection;
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
      if (!mounted || !ok) return;
    }
    setState(() {
      _needPhotos = false;
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

  Future<void> _resubmit() async {
    final bool ok = await _controller.resubmit(verificationResubmitMessage);
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

  Future<void> _onStart() async {
    if (!_collectingStart) {
      setState(() => _collectingStart = true);
      return;
    }
    final CapturedDocument? front = _front;
    final CapturedDocument? selfie = _selfie;
    if (front == null || selfie == null) {
      setState(() => _needPhotos = true);
      return;
    }
    final CapturedDocument? back = _back;
    final bool ok = await _controller.startVerification(
      idType: _controller.status?.idType ?? 'philid',
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
    if (!mounted || !ok) return;
    setState(() => _collectingStart = false);
  }

  Widget _startPhotos(String idLabel) {
    return S3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Send a new valid ID',
            style: s3Type(14, AppTypography.black, BrandColors.textPrimary),
          ),
          S3Field(
            label: 'Type of ID',
            asterisk: true,
            value: idLabel.isEmpty ? 'PhilSys National ID' : idLabel,
            chevron: true,
          ),
          S3Field(
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
              size: 16,
              color: BrandColors.taytayBlue,
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
              size: 16,
              color: BrandColors.taytayBlue,
            ),
          ),
          S3Field(
            label: 'Selfie',
            value: _slotLabel(
              file: _selfie,
              sent: false,
              empty: 'Previous selfie kept',
            ),
            readOnly: true,
            onTap: () => _pick(VerificationPhotoSlot.selfie),
            leading: const TaytayIcon(
              icon: TaytayIcons.check,
              semanticLabel: '',
              excludeSemantics: true,
              size: 16,
              color: BrandColors.success,
            ),
            trailing: const Text(
              'Retake',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: s3Line,
                leadingDistribution: TextLeadingDistribution.even,
                color: BrandColors.taytayBlue,
                decoration: TextDecoration.none,
              ),
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

String _noteLabel(VerificationItemCategory category) => switch (category) {
  VerificationItemCategory.personalDetails => 'Your details',
  VerificationItemCategory.address => 'Address',
  VerificationItemCategory.contact => 'Contact details',
  VerificationItemCategory.identityDocument => 'ID photo',
  VerificationItemCategory.photo => 'Photo of you',
};
