class AccessLog {
  final int id;
  final int userId;
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
    return AccessLog(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      userId: map['user_id'] is int ? map['user_id'] : int.parse(map['user_id'].toString()),
      timestamp: DateTime.parse(map['timestamp']),
      direction: map['direction'] ?? 'entry',
      isVisitor: map['is_visitor'] is bool
          ? map['is_visitor']
          : (map['is_visitor'].toString().toLowerCase() == 'true'),
      validatorName: map['validator_name'],
    );
  }
}