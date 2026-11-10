import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/loading_skeleton.dart';

/// Old programme page. The route paints the Tulong service for the same slug.
///
/// This widget is not the route. Building it opens `GET /services/{slug}`
/// through that page. There is no apply control.
class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({required this.programId, super.key});

  /// Service slug. The route parameter is still named `programId`.
  final String programId;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(
        AppRoute.programDetail.routeName,
        pathParameters: <String, String>{'programId': widget.programId},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // The redirect happens on the next frame. Until then the page shows the
    // detail skeleton the programme page itself loads with.
    return const ColoredBox(
      color: BrandColors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: LoadingSkeleton(
            layout: SkeletonLayout.detail,
            count: 1,
            semanticLabel: 'Opening the programme page',
          ),
        ),
      ),
    );
  }
}
