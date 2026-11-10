import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import 'blue_header.dart';
import 'network_status_views.dart';

/// A page reached from a list (settings, security, privacy): the blue
/// header with a back control over the `#F4F6FA` page, and the content in a
/// scrolling column with the 16 px gutter.
///
/// [offlineBanner] adds the app's offline strip under the header. Pages
/// inside the tab shell leave it off: the shell already draws one.
class SoftPage extends StatelessWidget {
  const SoftPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.actions = const <Widget>[],
    this.offlineBanner = false,
    this.scrollKey,
    this.footer,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool offlineBanner;
  final Key? scrollKey;

  /// Pinned under the scrolling content, e.g. a composer.
  final Widget? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final Widget? footer = this.footer;
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlueHeader(
            title: title,
            subtitle: subtitle,
            showBack: true,
            onBack: onBack,
            actions: actions,
          ),
          if (offlineBanner) const OfflineBanner(),
          Expanded(
            child: ListView(
              key: scrollKey,
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xl + (footer == null ? safeBottom : 0),
              ),
              children: children,
            ),
          ),
          ?footer,
        ],
      ),
    );
  }
}
