import 'package:flutter/services.dart';

/// Forces the School ID input to the strict `**-**-****` mask
/// (2 digits — 2 digits — 4 digits) dynamically as the user types.
///
/// Dashes are inserted/removed automatically and only digits are accepted.
class SchoolIdInputFormatter extends TextInputFormatter {
  static const int _maxDigits = 8; // 2 + 2 + 4

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only digits, capped at 8.
    final digits =
        newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped =
        digits.length > _maxDigits ? digits.substring(0, _maxDigits) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      buffer.write(capped[i]);
      // Insert dashes after the 2nd and 4th digit (but not trailing).
      if ((i == 1 || i == 3) && i != capped.length - 1) buffer.write('-');
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
