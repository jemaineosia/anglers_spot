String mapMoonPhase(double phase) {
  if (phase == 0) return "New Moon 🌑";
  if (phase > 0 && phase < 0.25) return "Waxing Crescent 🌒";
  if (phase == 0.25) return "First Quarter 🌓";
  if (phase > 0.25 && phase < 0.5) return "Waxing Gibbous 🌔";
  if (phase == 0.5) return "Full Moon 🌕";
  if (phase > 0.5 && phase < 0.75) return "Waning Gibbous 🌖";
  if (phase == 0.75) return "Last Quarter 🌗";
  if (phase > 0.75 && phase < 1.0) return "Waning Crescent 🌘";
  return "Unknown";
}
