import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';

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
    return const ColoredBox(
      color: BrandColors.surface,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
