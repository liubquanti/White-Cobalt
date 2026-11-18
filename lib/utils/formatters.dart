/// Human readable size, e.g. `1.5 GB`. Replaces the `filesize` package.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 || value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// Compares dotted versions (`10.2.1` vs `10.10`). Non-numeric parts count as
/// 0 instead of throwing, so one odd file name can't break the whole list.
int compareVersions(String a, String b) {
  List<int> parse(String v) =>
      v.split(RegExp(r'[.+-]')).map((p) => int.tryParse(p) ?? 0).toList();
  final pa = parse(a);
  final pb = parse(b);
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
