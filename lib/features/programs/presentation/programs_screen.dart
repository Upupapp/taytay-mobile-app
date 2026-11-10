import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/loading_skeleton.dart';

/// Old programmes list. The shell tab is Tulong, which reads `GET /services`.
///
/// This widget is not the route. Anything that still builds it goes to that
/// catalogue instead of calling `GET /programs`, which the Node contract does
/// not publish.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AppRoute.programs.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The redirect happens on the next frame. Until then the page shows the
    // loading state every list screen uses (the Tulong list's skeleton), on
    // the redesign background.
    return const ColoredBox(
      color: BrandColors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: LoadingSkeleton(count: 4, semanticLabel: 'Opening Tulong'),
        ),
      ),
    );
  }
}
