import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../domain/credential_repository.dart';

/// The resident's Taytay digital ID.
///
/// A credential is rendered from what the server issued, never assembled on
/// the device from profile fields. "Valid" is a server-side cryptographic
/// verdict — this screen may display a credential, and it never decides that
/// one is genuine.
///
/// A 404 or a null card keeps the not-issued card. The portrait media id is
/// not fetched: this client has no media-bytes route for it.
class DigitalIdScreen extends StatefulWidget {
  const DigitalIdScreen({super.key, this.repository});

  /// Set by tests. The app reads [CredentialRepository] from the scope.
  final CredentialRepository? repository;

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends State<DigitalIdScreen> {
  bool _started = false;
  ResidentCredential? _card;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final CredentialRepository? repository =
        widget.repository ??
        context
            .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
            ?.dependencies
            .credentialRepository;
    if (repository == null) return;
    unawaited(_load(repository));
  }

  Future<void> _load(CredentialRepository repository) async {
    final Result<ResidentCredential?> result = await repository
        .loadOwnCredential();
    if (!mounted) return;
    final ResidentCredential? card = result.valueOrNull;
    if (card == null) return;
    setState(() => _card = card);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ResidentCredential? card = _card;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const TaytayBackButton(),
        title: const Text('My Taytay ID'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  color: BrandColors.taytayBlue,
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'MUNICIPALITY OF TAYTAY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Resident Digital ID',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    Text(
                      card == null ? 'Not yet issued' : _statusLine(card),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                card == null
                    ? 'Your digital ID will appear here once Taytay LGU issues it.'
                    : 'Taytay LGU issued this card. A scanner checks the code. '
                          'This phone does not decide that the card is genuine.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Status and municipal number. The QR token is not painted.
  static String _statusLine(ResidentCredential card) {
    final String status = switch (card.state) {
      CredentialLifecycleState.active => 'Active',
      CredentialLifecycleState.suspended => 'Suspended',
      CredentialLifecycleState.revoked => 'Revoked',
      _ => 'Issued',
    };
    final String? number = card.idNumber;
    if (number == null || number.isEmpty) return status;
    return '$number · $status';
  }
}
