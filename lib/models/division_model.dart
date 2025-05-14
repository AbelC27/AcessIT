class Division {
  final int id;
  final String name;

  Division({required this.id, required this.name});

  factory Division.fromMap(Map<String, dynamic> map) {
    return Division(
      id: map['id'],
      name: map['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
