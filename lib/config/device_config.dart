class DeviceConfig {

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static double orbitRadius(BuildContext context) {

    final width =
        MediaQuery.of(context).size.width;

    if (width >= 900) {
      return 42;
    }

    return 36;
  }

  static double cardWidth(BuildContext context) {

    final width =
        MediaQuery.of(context).size.width;

    if (width >= 900) {
      return 320;
    }

    return 280;
  }
}