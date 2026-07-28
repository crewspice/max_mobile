import 'package:flutter/material.dart';

class DeviceConfig {

  // Change this when deploying
  static const String device = "moto_g";
  // static const String device = "iphone";
  // static const String device = "ipad";


  static bool get isIphone => device == "iphone";
  static bool get isIpad => device == "ipad";

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;


  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;


  static double orbitRadius() {
    switch (device) {
      case "iphone":
        return 0.645;

      case "ipad":
        return 0.465;

      case "moto_g":
      default:
        return 0.68;
    }
  }


  static double cardWidth(BuildContext context) {
    switch (device) {
      case "iphone":
        return 300;

      case "ipad":
        return 320;

      case "moto_g":
      default:
        return 280;
    }
  }


  static double actionButtonWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 900) {
      return 290; // iPad
    }

    if (width < 400) {
      return 95; // smaller iPhones
    }

    return 125; // Moto / larger phones
  }

  static double liftSelectorScale() {
    switch (device) {
      case "ipad":
        return 0.67;
      default:
        return 1.0;
    }
  }
}