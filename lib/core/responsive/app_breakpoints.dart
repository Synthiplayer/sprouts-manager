import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double phoneMaxWidth = 699;
  static const double tabletMaxWidth = 1199;

  static bool isDesktopPlatform() {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width <= phoneMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > phoneMaxWidth && width <= tabletMaxWidth;
  }

  static bool isDesktopWidth(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletMaxWidth;
  }

  static bool shouldOpenManagerDirectly(BuildContext context) {
    return isDesktopPlatform() || isDesktopWidth(context);
  }

  // For internal screen layouts only, not for auth/permission decisions.
  static bool preferAdmissionLayout(BuildContext context) {
    return isPhone(context) &&
        MediaQuery.of(context).orientation == Orientation.portrait;
  }
}
