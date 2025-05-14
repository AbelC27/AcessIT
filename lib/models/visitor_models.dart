class Visitor {
  final String name;
  final String licensePlate;
  final String reason;
  final String bleTempCode;
  final DateTime accessStart;
  final DateTime accessEnd;

  Visitor({
    required this.name,
    required this.licensePlate,
    required this.reason,
    required this.bleTempCode,
    required this.accessStart,
    required this.accessEnd,
  });

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      name: map['name'],
      licensePlate: map['license_plate'],
      reason: map['reason'],
      bleTempCode: map['ble_temp_code'],
      accessStart: DateTime.parse(map['access_start']),
      accessEnd: DateTime.parse(map['access_end']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'license_plate': licensePlate,
      'reason': reason,
      'ble_temp_code': bleTempCode,
      'access_start': accessStart.toIso8601String(),
      'access_end': accessEnd.toIso8601String(),
    };
  }
}
