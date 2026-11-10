import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/session/resident_capability.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../auth/domain/sign_in_challenge.dart';
import '../domain/profile_fields.dart';
import '../domain/resident_profile_detail.dart';

/// Edits the contact details the resident owns — and nothing else.
///
/// ---
///
/// **The form has exactly two fields because the contract authorises exactly
/// two.** `PATCH /api/v1/me/profile` is "contact fields only"; the update type
/// it maps to has no property for anything canonical; and this screen builds its
/// fields by filtering `ResidentProfileField` on ownership, so a field added to
/// the LGU-verified group can never appear here by accident. Three independent
/// reasons, each sufficient (acceptance 2).
///
/// **Changing a mobile number changes how the resident signs in.** The screen
/// says so before they submit, because the consequence is not obvious and the
/// cost of getting it wrong is being locked out of a government service.
class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({super.key});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _purok = TextEditingController();

  bool _started = false;
  bool _loading = false;
  bool _saving = false;
  AppFailure? _failure;

  /// Why the last save did not go through. Separate from a failed load.
  AppFailure? _saveFailure;
  bool _saved = false;

  /// One key per attempt, reused on retry: a dropped connection after the
  /// server committed is indistinguishable from one before it.
  String? _idempotencyKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _mobile.dispose();
    _street.dispose();
    _purok.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    if (!CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.manageAccount,
    )) {
      return;
    }

    setState(() => _loading = true);
    final result = await dependencies.residentProfileRepository.loadOwnDetail();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (detail) {
          _detail = detail;
          _mobile.text =
              detail.valueOf(ResidentProfileField.mobileNumber) ?? '';
          _email.text = detail.valueOf(ResidentProfileField.emailAddress) ?? '';
          _street.text =
              detail.valueOf(ResidentProfileField.streetAddress) ?? '';
          _purok.text = detail.valueOf(ResidentProfileField.purokOrSitio) ?? '';
        },
        onErr: (failure) => _failure = failure,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final dependencies = AppDependencies.of(context);
    final reduced = Motion.reduced(context);
    final update = ContactDetailsUpdate(
      mobileNumber: _mobile.text.trim(),
      streetAddress: _street.text.trim(),
      purokOrSitio: _purok.text.trim(),
      emailAddress: _email.text.trim(),
    );

    setState(() {
      _saving = true;
      _saveFailure = null;
      _saved = false;
    });
    _idempotencyKey ??= DateTime.now().microsecondsSinceEpoch.toString();

    final result = await dependencies.residentProfileRepository
        .updateContactDetails(update: update, idempotencyKey: _idempotencyKey!);
    if (!mounted) return;

    setState(() {
      _saving = false;
      result.fold(
        onOk: (_) {
          _saved = true;
          // Spent. The next edit is a new change, not a replay of this one.
          _idempotencyKey = null;
        },
        // The key is kept, so saving again replays this change.
        onErr: (failure) => _saveFailure = failure,
      );
    });

    await AppHaptics.fire(
      _saved ? HapticIntent.confirm : HapticIntent.error,
      suppressed: reduced,
    );
  }

  /// The last loaded profile, kept so the editable list follows the office's
  /// answer rather than this app's declaration (C-13).
  ResidentProfileDetail? _detail;

  @override
  Widget build(BuildContext context) {
    // Built from the ownership filter, not from a hand-written list: a field
    // that is not account-owned cannot appear on this screen.
    // The office's list when it published one; this app's declaration only as
    // a fallback (C-13). A field the server calls self-service belongs on this
    // screen even if the enum says otherwise — that disagreement was live for
    // `street_address`.
    final editable =
        _detail?.fieldsOwnedBy(FieldOwnership.accountOwned) ??
        ResidentProfileField.ownedBy(FieldOwnership.accountOwned);

    return AuthFormPage(
      title: 'Your account details',
      subtitle: profileSectionCopy(
        context,
        FieldOwnership.accountOwned,
      ).explanation,
      footer: _loading
          ? null
          : AppButton(
              label: 'Save changes',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
      child: CapabilityGate(
        capability: ResidentCapability.manageAccount,
        child: _loading
            ? const LoadingSkeleton(
                layout: SkeletonLayout.detail,
                semanticLabel: 'Loading your details',
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final field in editable) ...<Widget>[
                      _fieldFor(field),
                      const SizedBox(height: Spacing.formGap),
                    ],
                    const SizedBox(height: Spacing.sm),
                    const WhyWeAsk(
                      title: 'Why Taytay LGU keeps this',
                      purpose:
                          'Your mobile number is how Taytay LGU signs you in '
                          'and tells you about your requests. Your email is '
                          'optional and is used only to send you copies.',
                      whoSeesIt:
                          'Staff handling something you applied for. It is '
                          'never shared for advertising.',
                      ifYouDecline:
                          'Without a mobile number you cannot sign in. Email '
                          'can be left blank.',
                    ),
                    const SizedBox(height: Spacing.lg),
                    if (_saved)
                      const SoftNote(
                        tone: NoteTone.success,
                        message: 'Your contact details were updated.',
                      ),
                    // `PATCH /me` is wired, so a failure is the request's,
                    // not a feature that is switched off. Each value is set
                    // outright and the key is kept, so saving again is safe.
                    if (_saveFailure case final AppFailure failure)
                      failure.outcomeUnknown
                          ? const SoftNote(
                              tone: NoteTone.warning,
                              title: 'Your changes may not have been saved. ',
                              message:
                                  'We could not confirm them. Saving again '
                                  'is safe: the same details are sent '
                                  'again.',
                            )
                          : SoftNote(
                              tone: NoteTone.error,
                              title: 'Could not save your changes. ',
                              message:
                                  '${failure.residentMessage} Nothing was '
                                  'changed, and the municipal hall can '
                                  'update them for you.',
                            )
                    else if (_failure case final AppFailure failure)
                      SoftNote(
                        tone: NoteTone.error,
                        title: 'Could not load your details. ',
                        message: failure.residentMessage,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  /// CSS `.fld`: the label above a filled field, with the help under it.
  Widget _labelled(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AuthFieldLabel(label),
      const SizedBox(height: Spacing.sm),
      field,
    ],
  );

  static Widget _icon(IconData icon) => TaytayIcon(
    icon: icon,
    semanticLabel: '',
    excludeSemantics: true,
    size: IconSizes.sm,
  );

  Widget _fieldFor(ResidentProfileField field) => switch (field) {
    ResidentProfileField.mobileNumber => _labelled(
      profileFieldLabel(context, field),
      TextFormField(
        controller: _mobile,
        keyboardType: TextInputType.phone,
        autofillHints: const <String>[AutofillHints.telephoneNumber],
        // One field per editor screen, so the keyboard closes rather than
        // offering a "next" that goes nowhere.
        textInputAction: TextInputAction.done,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(SignInIdentifier.length),
        ],
        decoration: InputDecoration(
          hintText: '09XXXXXXXXX',
          // Stated before submission: changing this changes how they sign in.
          helperText: 'This is also how you sign in.',
          helperMaxLines: 2,
          prefixIcon: _icon(TaytayIcons.smartphone),
        ),
        // The same rule as sign-in, from the same definition, so the two cannot
        // disagree about what a valid Philippine mobile number looks like.
        validator: SignInIdentifier.validate,
      ),
    ),
    ResidentProfileField.emailAddress => _labelled(
      AppStrings.of(
        context,
      ).profileFieldOptionalSuffix(profileFieldLabel(context, field)),
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const <String>[AutofillHints.email],
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          helperText: profileFieldHint(context, field),
          helperMaxLines: 2,
          prefixIcon: _icon(TaytayIcons.mail),
        ),
        validator: _validateOptionalEmail,
      ),
    ),
    ResidentProfileField.streetAddress => _labelled(
      profileFieldLabel(context, field),
      TextFormField(
        controller: _street,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          helperText: profileFieldHint(context, field),
          helperMaxLines: 2,
          prefixIcon: _icon(TaytayIcons.house),
        ),
      ),
    ),
    ResidentProfileField.purokOrSitio => _labelled(
      AppStrings.of(
        context,
      ).profileFieldOptionalSuffix(profileFieldLabel(context, field)),
      TextFormField(
        controller: _purok,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          helperText: profileFieldHint(context, field),
          helperMaxLines: 2,
          prefixIcon: _icon(TaytayIcons.mapPin),
        ),
      ),
    ),
    // A field with no control here renders as nothing at all — the old comment
    // claimed adding one would be a compile error, and this catch-all is why it
    // never was. `profile_test.dart` asserts every account-owned field has a
    // control, which is the check that comment described.
    _ => const SizedBox.shrink(),
  };

  /// Optional, but must look like an address if given.
  ///
  /// Deliberately loose. Over-strict email validation rejects real addresses,
  /// and the server validates again — its answer is the one that counts.
  static String? _validateOptionalEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    if (!input.contains('@') || input.startsWith('@') || input.endsWith('@')) {
      return 'Enter an email address, or leave this blank.';
    }
    return null;
  }
}
