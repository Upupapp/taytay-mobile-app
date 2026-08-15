import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/assistance_program.dart';
import 'programs_screen.dart';

/// One assistance programme in full.
///
/// ---
///
/// **Everything here is text the office published.** Eligibility is rendered as
/// criteria to read, not evaluated; requirements are a list to bring, not a
/// checklist to satisfy; the maximum grant is a ceiling the LGU stated, not an
/// amount this resident will receive. The screen says so in two places, because
/// this is the screen where a resident is most likely to conclude they have been
/// approved or refused (acceptance 2).
///
/// **Timing is quoted, never computed.** The app does not turn dates into "open"
/// or "closed": a window that has passed on a phone clock may still be open at
/// the counter, and an app that says "closed" sends somebody away from help they
/// could still have received. Availability is backend-driven (acceptance 3).
///
/// **The CTA explains; it never submits.** `POST /me/assistance-requests` is
/// `planned`, so there is nothing to send — and a resident who has just come
/// back through a sign-in gate must be shown what applying involves rather than
/// have it done in their name.
class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({required this.programCode, super.key});

  final String programCode;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  bool _started = false;
  bool _loading = false;
  AssistanceProgram? _program;

  bool get _codeIsValid => DeepLink.isValidIdentifier(widget.programCode);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !_codeIsValid) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    if (!CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.browsePrograms,
    )) {
      return;
    }

    setState(() => _loading = true);
    final result = await dependencies.programRepository.loadProgram(
      widget.programCode,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _program = result.valueOrNull;
    });
  }

  Future<void> _apply(AssistanceProgram program) async {
    final dependencies = AppDependencies.of(context);
    final verdict = CapabilityService.evaluate(
      session: dependencies.session.state,
      capability: ResidentCapability.trackAssistanceRequests,
    );

    if (verdict is CapabilityUsable || verdict is CapabilityNotYetAvailable) {
      dependencies.intents.remember(
        ResidentIntentKind.applyForService,
        targetId: program.code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Applying in this app is not switched on yet. Bring the documents '
            'listed here to the Taytay municipal hall.',
          ),
        ),
      );
      return;
    }

    await AccessGateSheet.showForCapability(
      context: context,
      verdict: verdict,
      intent: ResidentIntentKind.applyForService,
      targetId: program.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;

    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.browsePrograms,
          child: switch ((_codeIsValid, _loading, program)) {
            (false, _, _) => const _NotAvailable(),
            (_, true, null) => const AppLoadingView(
              message: 'Opening programme…',
            ),
            (_, _, null) => const _NotAvailable(),
            (_, _, final AssistanceProgram loaded) => _Detail(
              program: loaded,
              onApply: () => _apply(loaded),
            ),
          },
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.program, required this.onApply});

  final AssistanceProgram program;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availability = program.availabilityNote;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(program.name, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: Spacing.sm),
        Text(program.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: Spacing.lg),

        const ProgramGuidanceNotice(),
        const SizedBox(height: Spacing.lg),

        if (program.hasEligibility) ...<Widget>[
          _Section(
            title: 'Who this is meant to help',
            // Named as guidance in the heading itself, not only in a footnote.
            subtitle:
                'Taytay LGU published these guidelines. Staff decide each '
                'application individually.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final criterion in program.eligibility)
                  _Bullet(
                    text: criterion.text,
                    label: criterion.category,
                    icon: Icons.circle_outlined,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
        ],

        if (program.hasRequirements) ...<Widget>[
          _Section(
            title: 'What to bring',
            subtitle: 'Taytay LGU asks applicants for these.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final requirement in program.requirements)
                  _Bullet(
                    text: requirement.text,
                    label: requirement.isOptional ? 'Optional' : null,
                    icon: Icons.description_outlined,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
        ],

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text('Details', style: theme.textTheme.titleSmall),
              ),
              const SizedBox(height: Spacing.sm),
              _Line(label: 'Reference code', value: program.code),
              _Line(label: 'Category', value: program.category),
              _Line(label: 'Run by', value: program.owningOffice),
              _Line(label: 'Contact', value: program.contact),
              _Line(label: 'Legal basis', value: program.legalBasis),
              _Line(
                label: 'Most that can be granted',
                value: program.maximumGrant,
              ),
              _Line(label: 'When', value: availability),
              _Line(label: 'Where to apply', value: program.applicationChannel),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        const AppBanner(
          tone: BannerTone.info,
          title: 'What happens next',
          message:
              'Taytay LGU staff assess every application against the current '
              'rules and the documents you bring. This app cannot tell you the '
              'outcome in advance, and nothing here is a promise of approval.',
        ),
        const SizedBox(height: Spacing.xl),

        AppButton(label: 'How to apply', onPressed: onApply),
        const SizedBox(height: Spacing.sm),
        Text(
          'Nothing is submitted by tapping this.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon, this.label});

  final String text;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: IconSizes.sm, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (label != null)
                  Text(
                    label!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value;
    // Absent fields are omitted rather than shown empty: the office simply did
    // not publish one, and a blank row invites a resident to think it was lost.
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable();

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'This programme is not available',
      kind: StatusKind.empty,
      icon: Icons.link_off_outlined,
      message: DeepLinkRejection.unknownTarget.residentMessage,
      primaryAction: FilledButton(
        onPressed: () => context.goNamed(AppRoute.programs.routeName),
        child: const Text('See all programmes'),
      ),
    );
  }
}
