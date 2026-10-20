import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import 'taytay_back_button.dart';
import 'taytay_rows.dart';

/// A labelled stand-in for a screen a later sprint draws.
///
/// The copy says the page is not live. It does not invent an office, a
/// hotline or a message and present it as something Taytay LGU published.
class FoundationPlaceholderScreen extends StatelessWidget {
  const FoundationPlaceholderScreen({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const TaytayBackButton(),
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: <Widget>[
            const SampleTag(),
            const SizedBox(height: Spacing.md),
            Text(body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
