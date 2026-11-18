/// Uptime monitor shown on the service status page.
class MonitorStatus {
  const MonitorStatus({required this.name, required this.statusClass, required this.dailyColors});

  final String? name;

  /// `success`, `danger`, `warning` or anything else (unknown).
  final String statusClass;

  /// Last 90 days, one colour name (`green`, `red`, …) per day.
  final List<String> dailyColors;

  static List<MonitorStatus> listFromJson(Object? json) {
    final data = json is Map ? json['data'] : null;
    if (data is! List) return const [];
    return [
      for (final m in data.whereType<Map>())
        MonitorStatus(
          name: m['name']?.toString(),
          statusClass: m['statusClass']?.toString() ?? '',
          dailyColors: m['dailyRatios'] is List
              ? [for (final d in m['dailyRatios'] as List) (d is Map ? d['color'] : null)?.toString() ?? '']
              : const [],
        ),
    ];
  }
}

/// Device-wide storage numbers from the native side.
class DeviceStorage {
  const DeviceStorage({required this.total, required this.free});

  static const empty = DeviceStorage(total: 0, free: 0);

  final int total;
  final int free;

  int get used => total - free;
}

/// Bytes downloaded by White Cobalt for one service (folder name).
class ServiceUsage {
  const ServiceUsage(this.service, this.bytes);

  final String service;
  final int bytes;
}
