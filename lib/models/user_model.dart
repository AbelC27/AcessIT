// Root: lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final int divisionId;
  final String photoUrl;
  final String badgeNumber;
  final String bluetoothCode;
  final bool accessEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.divisionId,
    required this.photoUrl,
    required this.badgeNumber,
    required this.bluetoothCode,
    required this.accessEnabled,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      divisionId: map['division_id'] ?? 0,
      photoUrl: map['photo_url'] ?? '',
      badgeNumber: map['badge_number'] ?? '',
      bluetoothCode: map['bluetooth_code'] ?? '',
      accessEnabled: map['access_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'division_id': divisionId,
      'photo_url': photoUrl,
      'badge_number': badgeNumber,
      'bluetooth_code': bluetoothCode,
      'access_enabled': accessEnabled,
    };
  }
}
