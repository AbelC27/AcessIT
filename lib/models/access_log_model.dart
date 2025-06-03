class AccessLog {
  final int id;
  final String userId;
  final DateTime timestamp;
  final String direction; // 'entry' or 'exit'
  final bool isVisitor;
  final String? validatorName; // Numele validatorului (poate fi null)

  AccessLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.direction,
    required this.isVisitor,
    this.validatorName,
  });

  factory AccessLog.fromMap(Map<String, dynamic> map) {
    print('Parsing log map: $map');
    return AccessLog(
      id: map['id'],
      userId: map['user_id']?.toString() ?? '-', // dacă e null, fallback
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      direction: map['direction']?.toString() ?? 'entry',
      isVisitor: map['is_visitor'] ?? false,
      validatorName: map['validated_by']?.toString(),
    );
  }
}