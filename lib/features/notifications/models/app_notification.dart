class AppNotification {
  const AppNotification({
    required this.id,
    required this.event,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    this.readAt,
  });

  final String id;
  final String event;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({
    String? id,
    String? event,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    Object? readAt = _unset,
  }) {
    return AppNotification(
      id: id ?? this.id,
      event: event ?? this.event,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt == _unset ? this.readAt : readAt as DateTime?,
    );
  }

  factory AppNotification.fromSocketMessage(Map<String, dynamic> json) {
    final data = _mapFrom(json['data']);
    final timestamp =
        DateTime.tryParse('${json['timestamp']}') ?? DateTime.now().toUtc();
    final id = _stringOrNull(json['notification_id']) ??
        _stringOrNull(data['notification_id']) ??
        '${json['event'] ?? 'notification'}-${timestamp.toIso8601String()}';

    return AppNotification(
      id: id,
      event: _stringOrNull(json['event']) ?? 'notification',
      title: _stringOrNull(json['title']) ?? 'Notification',
      body: _stringOrNull(json['body']) ?? '',
      data: data,
      timestamp: timestamp,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _stringOrNull(json['id']) ?? '',
      event: _stringOrNull(json['event']) ?? 'notification',
      title: _stringOrNull(json['title']) ?? 'Notification',
      body: _stringOrNull(json['body']) ?? '',
      data: _mapFrom(json['data']),
      timestamp:
          DateTime.tryParse('${json['timestamp']}') ?? DateTime.now().toUtc(),
      readAt: _stringOrNull(json['read_at']) == null
          ? null
          : DateTime.tryParse('${json['read_at']}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event': event,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
      };
}

const Object _unset = Object();

String? _stringOrNull(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return const {};
}
