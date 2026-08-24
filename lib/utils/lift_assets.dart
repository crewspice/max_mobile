// Maps a lift type code (e.g. "12M", "26S") to its icon asset.
// Shared between the truck yard map and the maintenance yard list so the
// two views stay visually consistent.
String liftAssetPath(String? liftType) {
  switch ((liftType ?? '').trim().toLowerCase()) {
    case "12m":
      return "assets/12m.png";
    case "19s":
      return "assets/19s.png";
    case "26":
      return "assets/26.png";
    case "26s":
      return "assets/26s.png";
    case "32":
      return "assets/32.png";
    case "33rt":
      return "assets/33rt.png";
    case "40":
      return "assets/40.png";
    case "45b":
      return "assets/45b.png";
    default:
      return "assets/26.png"; // fallback
  }
}
