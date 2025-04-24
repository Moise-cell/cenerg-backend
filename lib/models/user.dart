enum UserRole {
  owner,    // Propriétaire
  house1,   // Maison 1
  house2    // Maison 2
}

class User {
  final String id;
  final String username;
  final UserRole role;
  final String? houseId;  // Null pour le propriétaire
  final String? houseName;
  final bool isActive;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.houseId,
    this.houseName,
    this.isActive = true,
    DateTime? lastLogin,
  }) : lastLogin = lastLogin ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: _roleFromString(json['role']),
      houseId: json['house_id'],
      houseName: json['house_name'],
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
        ? DateTime.parse(json['last_login'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role.toString().split('.').last,
      'house_id': houseId,
      'house_name': houseName,
      'is_active': isActive,
      'last_login': lastLogin.toIso8601String(),
    };
  }

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'house1':
        return UserRole.house1;
      case 'house2':
        return UserRole.house2;
      default:
        throw Exception('Role invalide: $role');
    }
  }

  bool get isOwner => role == UserRole.owner;
  bool get isHouse1 => role == UserRole.house1;
  bool get isHouse2 => role == UserRole.house2;
  bool get isHouse => isHouse1 || isHouse2;
}
