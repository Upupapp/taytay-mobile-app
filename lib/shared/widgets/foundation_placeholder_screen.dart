import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import 'taytay_back_button.dart';
import 'taytay_headers.dart';
import 'taytay_rows.dart';

/// A labelled stand-in for a screen a later sprint draws.
///
/// The copy says the page is not live. It does not invent an office, a
/// hotline or a message and present it as something Taytay LGU published.
class FoundationPlaceholderScreen extends StatelessWidget {
  const FoundationPlaceholderScreen({
    required this.title,
    required this.body,
    this.sealHeader = false,
    super.key,
  });

  final String title;
  final String body;

  /// Welcome and sign-in stand-ins carry the official seal.
  final bool sealHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sealHeader) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const WovenHeader(showBack: true),
              Expanded(
                child: _Body(
                  title: title,
                  body: body,
                  theme: theme,
                  showTitle: true,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const TaytayBackButton(),
        title: Text(title),
      ),
      body: SafeArea(
        child: _Body(title: title, body: body, theme: theme),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.title,
    required this.body,
    required this.theme,
    this.showTitle = false,
  });

  final String title;
  final String body;
  final ThemeData theme;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        if (showTitle) ...<Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.md),
        ],
        const SampleTag(),
        const SizedBox(height: Spacing.md),
        Text(body, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
