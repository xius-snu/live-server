/// Format a number as a comma-separated integer string.
/// e.g. 1234567.89 → "1,234,568"
String fmtCommas(double value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
