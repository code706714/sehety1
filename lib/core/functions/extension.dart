import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

bool isArabic(BuildContext context) {
  return context.locale.languageCode == 'ar';
}

extension LocaleExtension on BuildContext {
  bool get isArabic => locale.languageCode == 'ar';
}

extension SizedBix on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}
