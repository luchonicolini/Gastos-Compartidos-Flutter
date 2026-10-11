import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

IconData groupIconFromName(String? iconName) {
  switch (iconName) {
    case 'briefcase':
      return Icons.business_center_outlined;
    case 'beach':
      return Icons.beach_access_outlined;
    case 'mountain':
      return Icons.terrain_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'toast':
      return Icons.wine_bar_outlined;
    case 'flight':
    default:
      return Icons.flight_takeoff_rounded;
  }
}

Color groupColorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return AppPalette.lightTeal;
  final clean = hex.replaceAll('#', '');
  final val = int.tryParse('FF$clean', radix: 16);
  return val != null ? Color(val) : AppPalette.lightTeal;
}
