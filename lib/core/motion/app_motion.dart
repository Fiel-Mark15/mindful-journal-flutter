import 'package:flutter/material.dart';

class AppMotion {
  static const fast = Duration(milliseconds: 170);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 440);
  static const curve = Curves.easeOutCubic;
  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}
