String normalizeMoonPhase(dynamic raw) {
  if (raw == null) return "UNKNOWN";
  final value = raw.toString().toUpperCase();

  if (value.contains("NEW")) return "NEW_MOON";
  if (value.contains("FULL")) return "FULL_MOON";
  if (value.contains("QUARTER")) return "QUARTER";
  return "UNKNOWN";
}
