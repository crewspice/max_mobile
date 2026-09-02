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


  static double actionButtonWidth() {
    switch (device) {
      case "iphone":
        return 175;

      case "ipad":
        return 290;

      case "moto_g":
      default:
        return 125;
    }
  }

  static double liftSelectorScale() {
    switch (device) {
      case "ipad":
        return 0.67;
      default:
        return 1.0;
    }
  }

  // Growth factor for circular option buttons (record/history rows in the
  // maintenance workspace) — iPad has room to make them noticeably bigger.
  static double circleScale() {
    switch (device) {
      case "ipad":
        return 1.7;
      default:
        return 1.0;
    }
  }

  // Extra text-only growth for those same circular buttons, layered on top
  // of circleScale(). moto_g keeps the circle itself at its normal size but
  // wants the label to read bigger, spanning more of the circle.
  static double circleTextScale() {
    switch (device) {
      case "moto_g":
        return 1.5;
      default:
        return 1.0;
    }
  }

  // Growth factor for the maintenance workspace's curved-border boxes
  // (needs-PM/needs-repair/record-repair) - phone and tablet screens both
  // have plenty of spare room around those cards, so their text and
  // elements scale up rather than sitting at moto_g's baseline size.
  static double get maintenanceBoxScale {
    if (isIphone) return 1.4;
    if (isIpad) return 1.8;
    return 1.0;
  }

  // Growth factor for the maintenance timeline's circular nodes and the
  // user-avatar circles inside its event cards - iPad only, since that's
  // the only device with enough spare width for bigger nodes.
  static double get timelineNodeScale => isIpad ? 1.5 : 1.0;
}