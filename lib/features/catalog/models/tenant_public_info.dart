class TenantStatusInfo {
  const TenantStatusInfo({
    required this.isOpen,
    required this.estimatedPrepTimeMinutes,
    required this.activeOrdersCount,
    this.message,
    this.nextOpening,
  });

  final bool isOpen;
  final int estimatedPrepTimeMinutes;
  final int activeOrdersCount;
  final String? message;
  final String? nextOpening;

  factory TenantStatusInfo.fromJson(Map<String, dynamic> json) {
    return TenantStatusInfo(
      isOpen: json['is_open'] == true,
      estimatedPrepTimeMinutes: _readInt(json['estimated_prep_time_minutes']),
      activeOrdersCount: _readInt(json['active_orders_count']),
      message: json['message']?.toString(),
      nextOpening: json['next_opening']?.toString(),
    );
  }
}

class BusinessHourInfo {
  const BusinessHourInfo({
    required this.id,
    required this.dayOfWeek,
    required this.slotIndex,
    required this.opensAt,
    required this.closesAt,
    required this.isActive,
  });

  final int id;
  final int dayOfWeek;
  final int slotIndex;
  final String opensAt;
  final String closesAt;
  final bool isActive;

  factory BusinessHourInfo.fromJson(Map<String, dynamic> json) {
    return BusinessHourInfo(
      id: _readInt(json['id']),
      dayOfWeek: _readInt(json['day_of_week']),
      slotIndex: _readInt(json['slot_index']),
      opensAt: json['opens_at']?.toString() ?? '',
      closesAt: json['closes_at']?.toString() ?? '',
      isActive: json['is_active'] != false,
    );
  }

  String get opensShort => _shortTime(opensAt);
  String get closesShort => _shortTime(closesAt);
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _shortTime(String value) {
  return value.length >= 5 ? value.substring(0, 5) : value;
}
