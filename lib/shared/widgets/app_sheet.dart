import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// The app's modal bottom sheet, **for pickers only**: a list of choices the
/// resident picks one from (a barangay, an ID type, a topic, where a file
/// comes from). Every gate, notice, confirmation and decision is a centred
/// dialog instead (`AppDialog.show`; design rule: popups are centred).
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

/// One choice in a picker sheet: a row at least 48 dp tall, announced as a
/// button in a group where one is selected, with a tick on the chosen one.
class PickerChoiceRow extends StatelessWidget {
  const PickerChoiceRow({
    required this.rowKey,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// On the tappable row itself, for a test to tap.
  final Key rowKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: rowKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.sectionTitle.copyWith(
                      fontWeight: selected
                          ? AppTypography.strong
                          : AppTypography.medium,
                      color: selected ? BrandColors.blue : BrandColors.ink,
                    ),
                  ),
                ),
                if (selected)
                  const TaytayIcon(
                    icon: TaytayIcons.check,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: IconSizes.sm,
                    color: BrandColors.taytayBlue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
