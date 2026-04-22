import 'role_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final RoleModel? role;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] != null
          ? RoleModel.fromJson(json['role'])
          : null,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'name': name,
      'email': email,
      'created_at': createdAt,
      'role': role?.toJson(),
    };
  }
}