class RoleModel {
  final int id;
  final String name;

  RoleModel({
    required this.id,
    required this.name,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      // ✅ Handle both 'id' and 'role_id', and fallback to 0 if neither is provided by the WebSocket
      id: json['id'] ?? json['role_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}