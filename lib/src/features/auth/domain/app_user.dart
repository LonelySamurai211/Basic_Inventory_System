import 'dart:convert';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.age,
    this.position,
    this.avatarUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'staff',
      age: map['age'] is num
          ? (map['age'] as num).toInt()
          : int.tryParse(map['age']?.toString() ?? ''),
      position: map['position']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String role;
  final int? age;
  final String? position;
  final String? avatarUrl;

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'age': age,
      'position': position,
      'avatar_url': avatarUrl,
    };
  }

  String toJson() => jsonEncode(toMap());

  static AppUser? fromJson(String? source) {
    if (source == null || source.isEmpty) return null;
    return AppUser.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  AppUser copyWith({
    String? fullName,
    String? role,
    int? age,
    String? position,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      age: age ?? this.age,
      position: position ?? this.position,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
