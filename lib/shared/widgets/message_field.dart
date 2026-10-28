import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';

/// The Directory compose message field.
///
/// A "Message" label, then a 170 dp white box with a 12 dp radius and a 1.3 px
/// `#D6DCE8` border. Directory paints a draft when [controller] is null. A
/// resident types when a controller is supplied.
class MessageField extends StatelessWidget {
  const MessageField({
    this.controller,
    this.preview = '',
    this.fieldKey,
    super.key,
  });

  final TextEditingController? controller;

  /// Shown when there is no [controller]. Directory's design frames use this.
  final String preview;

  /// Key of the text field. Absent on the preview, which is not a field.
  final Key? fieldKey;

  static const TextStyle body = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle _label = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: BrandColors.fieldLabel,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final TextEditingController? field = controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 5),
          child: Text('Message', style: _label),
        ),
        Container(
          height: 170,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10.67, 12, 0),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6DCE8), width: 1.3),
          ),
          child: field == null
              ? Text(preview, style: body)
              : TextField(
                  key: fieldKey,
                  controller: field,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: body,
                  cursorColor: BrandColors.taytayBlue,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
        ),
      ],
    );
  }
}
