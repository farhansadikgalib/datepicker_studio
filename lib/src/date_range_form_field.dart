import 'package:flutter/material.dart';

import 'date_range_field.dart';
import 'models.dart';
import 'theme.dart';

/// A [FormField] wrapper around [DateRangeField], so a range participates in a
/// [Form] with validation, saving, and auto-validation.
///
/// ```dart
/// Form(
///   key: _formKey,
///   child: DateRangeFormField(
///     initialValue: _range,
///     validator: (r) => r == null ? 'Pick a period' : null,
///     onSaved: (r) => _range = r,
///   ),
/// )
/// ```
///
/// The validator's message is rendered as the field's error text, and
/// [Form.validate]/[Form.save] work as they do for any built-in form field.
class DateRangeFormField extends FormField<PickedDateRange> {
  // `enabled` is forwarded to super but also read by the builder closure, so it
  // cannot become a super parameter.
  // ignore: use_super_parameters
  DateRangeFormField({
    super.key,
    super.initialValue,
    super.validator,
    super.onSaved,
    AutovalidateMode? autovalidateMode,
    // Kept local (not a super parameter) because the builder closure reads it.
    bool enabled = true,
    ValueChanged<PickedDateRange?>? onChanged,
    DateRangePickerConfig config = const DateRangePickerConfig(),
    DateRangePickerTheme? theme,
    InputDecoration? decoration,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
    TextStyle? textStyle,
    String hintText = 'Select date range',
    String dateFormat = 'dd MMM yyyy',
    String separator = '  →  ',
    bool showClearButton = true,
    DateRangePickerPresentation presentation =
        DateRangePickerPresentation.sheet,
  }) : super(
         enabled: enabled,
         autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
         builder: (field) {
           // No hardcoded border — DateRangeField rounds it with borderRadius.
           final base =
               decoration ??
               const InputDecoration(
                 prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
               );
           return DateRangeField(
             value: field.value,
             enabled: enabled,
             onChanged: (range) {
               field.didChange(range);
               onChanged?.call(range);
             },
             config: config,
             theme: theme,
             // Surface the validator's message under the field.
             decoration: base.copyWith(errorText: field.errorText),
             borderRadius: borderRadius,
             textStyle: textStyle,
             hintText: hintText,
             dateFormat: dateFormat,
             separator: separator,
             showClearButton: showClearButton,
             presentation: presentation,
           );
         },
       );
}
