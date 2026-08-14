import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// The app's modal bottom sheet.
///
/// Wraps `showModalBottomSheet` with the three things every call site needs and
/// half of them forget:
///
/// * **`isScrollControlled` with a height cap.** Without it a sheet is limited to
///   half the screen and its content is clipped at a large text scale — the
///   residents who most need the larger text are the ones who then cannot read
///   the sheet.
/// * **Safe-area and keyboard insets.** A sheet containing a field must rise
///   above the keyboard rather than sit behind it.
/// * **A drag handle and a title that a screen reader announces**, so the sheet
///   is identifiable and dismissible without sight.
abstract final class AppSheet {
  /// Maximum height, as a fraction of the screen. Leaves the top of the
  /// underlying screen visible so the sheet reads as a layer over context
  /// rather than as a new page.
  static const double maxHeightFraction = 0.9;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      useSafeArea: true,
      showDragHandle: dismissible,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      builder: (context) => _SheetFrame(title: title, child: builder(context)),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Lifts the sheet above the keyboard when a field inside it has focus.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              0,
              Spacing.xl,
              Spacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleLarge),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                0,
                Spacing.xl,
                Spacing.xl,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
