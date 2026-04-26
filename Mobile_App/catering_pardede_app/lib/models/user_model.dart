import 'role_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profilePicture;
  final RoleModel? role;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePicture,
    this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
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
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'created_at': createdAt,
      'role': role?.toJson(),
    };
  }
}