import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';

/// The resident's Taytay digital ID.
///
/// Reachable only by a verified resident — the access guard sends everyone else
/// to verification. The credential itself (card artifact, QR material, offline
/// validity) belongs to the backend's `Credential` module and lands in a later
/// TAB; the placeholder here exists so the verified-only route is real and
/// testable.
///
/// Two rules already apply to this screen and are recorded now, before there is
/// anything to get wrong:
///
/// * a credential is rendered from what the server issued, never assembled on
///   the device from profile fields;
/// * "valid" is a server-side cryptographic verdict — this screen may display a
///   credential, but it never decides that one is genuine.
class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Taytay ID')),
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
                      'Not yet issued',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Your digital ID will appear here once Taytay LGU issues it.',
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
}
