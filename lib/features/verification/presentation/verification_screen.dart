import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../profile/domain/profile_fields.dart';
import '../domain/field_correction_note.dart';
import '../domain/verification_face.dart';
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
  bool _started = false;
  String? _tier;
  String? _reason;
  String _email = '';
  String _accountCreated = '';
  bool _tierReady = false;

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

  VerificationFace get _face {
    final VerificationStatusDetail? status = _controller.status;
    final String? raw = (_tier != null && _tier!.isNotEmpty)
        ? _tier
        : status?.rawState;
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
      ),
      VerificationFace.needsCorrection => NeedsCorrectionPage(
        onBack: () => _leave(context),
        // rejection_reason from GET /me. The verification request is not a
        // source of text a resident reads.
        reason: _reason ?? '',
        notes: _notes,
        idType: idLabel,
        reviewedOn: reviewed,
        onResubmit: () => context.goNamed(AppRoute.residentProfile.routeName),
      ),
      VerificationFace.unverified => UnverifiedStatusPage(
        onBack: () => _leave(context),
        onStart: () => context.goNamed(AppRoute.residentProfile.routeName),
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

String _noteLabel(VerificationItemCategory category) => switch (category) {
  VerificationItemCategory.personalDetails => 'Your details',
  VerificationItemCategory.address => 'Address',
  VerificationItemCategory.contact => 'Contact details',
  VerificationItemCategory.identityDocument => 'ID photo',
  VerificationItemCategory.photo => 'Photo of you',
};
