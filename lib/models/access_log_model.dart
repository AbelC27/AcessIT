class AccessLog {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String direction; // 'entry' or 'exit'
  final bool isVisitor;

  AccessLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.direction,
    required this.isVisitor,
  });

  factory AccessLog.fromMap(Map<String, dynamic> map) {
    return AccessLog(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      direction: map['direction'] ?? 'entry',
      isVisitor: map['is_visitor'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'direction': direction,
      'is_visitor': isVisitor,
    };
  }
}
