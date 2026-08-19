import 'package:cabme/common/widget/modern_datetime_picker.dart';
import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime(BuildContext context) async {
  // Use the modern Cupertino-style date time picker
  return await ModernDateTimePicker.show(context);
}
