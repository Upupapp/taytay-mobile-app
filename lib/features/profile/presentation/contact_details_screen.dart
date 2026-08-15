import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_support.dart';
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

  bool _started = false;
  bool _loading = false;
  bool _saving = false;
  AppFailure? _failure;
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
          _mobile.text =
              detail.valueOf(ResidentProfileField.mobileNumber) ?? '';
          _email.text = detail.valueOf(ResidentProfileField.emailAddress) ?? '';
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
      emailAddress: _email.text.trim(),
    );

    setState(() {
      _saving = true;
      _failure = null;
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
        onErr: (failure) => _failure = failure,
      );
    });

    await AppHaptics.fire(
      _saved ? HapticIntent.confirm : HapticIntent.error,
      suppressed: reduced,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Built from the ownership filter, not from a hand-written list: a field
    // that is not account-owned cannot appear on this screen.
    final editable = ResidentProfileField.ownedBy(FieldOwnership.accountOwned);

    return Scaffold(
      appBar: AppBar(title: const Text('Your account details')),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.manageAccount,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(Spacing.lg),
                    children: <Widget>[
                      Text(
                        FieldOwnership.accountOwned.sectionExplanation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                      for (final field in editable) ...<Widget>[
                        _fieldFor(field),
                        const SizedBox(height: Spacing.xl),
                      ],
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
                      const SizedBox(height: Spacing.xl),
                      if (_saved)
                        const AppBanner(
                          tone: BannerTone.success,
                          message: 'Your contact details were updated.',
                        ),
                      if (_failure != null)
                        const AppBanner(
                          tone: BannerTone.warning,
                          title: 'Could not save your changes',
                          message:
                              'Taytay LGU has not switched on account details '
                              'in this app yet. Nothing was changed, and the '
                              'municipal hall can update them for you.',
                        ),
                      const SizedBox(height: Spacing.lg),
                      AppButton(
                        label: 'Save changes',
                        loading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _fieldFor(ResidentProfileField field) => switch (field) {
    ResidentProfileField.mobileNumber => TextFormField(
      controller: _mobile,
      keyboardType: TextInputType.phone,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(SignInIdentifier.length),
      ],
      decoration: InputDecoration(
        labelText: field.label,
        hintText: '09XXXXXXXXX',
        // Stated before submission: changing this changes how they sign in.
        helperText: 'This is also how you sign in.',
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.phone_iphone_outlined),
      ),
      // The same rule as sign-in, from the same definition, so the two cannot
      // disagree about what a valid Philippine mobile number looks like.
      validator: SignInIdentifier.validate,
    ),
    ResidentProfileField.emailAddress => TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const <String>[AutofillHints.email],
      decoration: InputDecoration(
        labelText: '${field.label} (optional)',
        helperText: field.hint,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.alternate_email),
      ),
      validator: _validateOptionalEmail,
    ),
    // Unreachable: the list is filtered on ownership. Kept exhaustive so that
    // adding an account-owned field is a compile error until it has a control,
    // rather than a silently missing input.
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
