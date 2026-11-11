import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../core/result/result.dart';
import '../../features/registration/domain/registration_domain.dart';
import 'app_button.dart';
import 'app_sheet.dart';
import 'loading_skeleton.dart';

/// Opens the barangay picker in the app's picker sheet (`AppSheet`; a list of
/// choices is the one popup that may come up from the bottom) and resolves to
/// the barangay the resident chose, or null when they closed it.
///
/// [load] gives the list — `GET /barangays` through `BarangayDirectory`, or a
/// list the screen already holds. Sign-up and Edit profile both open this
/// one picker, so a barangay is chosen the same way wherever it is chosen.
Future<Barangay?> showBarangayPicker(
  BuildContext context, {
  required Future<Result<List<Barangay>>> Function() load,
  String? selectedId,
}) {
  return AppSheet.show<Barangay>(
    context: context,
    title: BarangayPicker.title,
    builder: (BuildContext sheet) =>
        BarangayPicker(load: load, selectedId: selectedId),
  );
}

/// Taytay's barangays, one 48 dp row each: the content of the sheet
/// [showBarangayPicker] opens.
///
/// A modal sheet so focus stays inside it and Back closes it. Loading and a
/// failed read are said in words, with a way to try again; nothing is picked
/// on the resident's behalf and there is no typed fallback.
class BarangayPicker extends StatefulWidget {
  const BarangayPicker({required this.load, this.selectedId, super.key});

  /// The sheet's title.
  static const String title = 'Choose your barangay';

  final Future<Result<List<Barangay>>> Function() load;
  final String? selectedId;

  @override
  State<BarangayPicker> createState() => _BarangayPickerState();
}

class _BarangayPickerState extends State<BarangayPicker> {
  Result<List<Barangay>>? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    setState(() => _result = null);
    final Result<List<Barangay>> result = await widget.load();
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle note = AppTypography.listDetail.copyWith(
      color: BrandColors.muted,
      height: 1.45,
    );
    final Result<List<Barangay>>? result = _result;
    final Widget body = switch (result) {
      null => const LoadingSkeleton(
        layout: SkeletonLayout.text,
        semanticLabel: 'Loading barangays',
      ),
      Ok<List<Barangay>>(:final value) when value.isNotEmpty => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Barangay barangay in value)
            PickerChoiceRow(
              rowKey: Key('barangay-${barangay.id}'),
              label: barangay.name,
              selected: barangay.id == widget.selectedId,
              onTap: () => Navigator.of(context).pop(barangay),
            ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              result is Ok<List<Barangay>>
                  ? 'No barangays are listed yet. Please try again later.'
                  : 'We could not load the list of barangays. Check your '
                        'connection and try again.',
              style: note,
            ),
          ),
          const SizedBox(height: Spacing.md),
          AppButton(label: 'Try again', onPressed: _fetch),
        ],
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Taytay, Rizal', style: note),
        const SizedBox(height: Spacing.sm),
        body,
      ],
    );
  }
}
