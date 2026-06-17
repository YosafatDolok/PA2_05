class RoleModel {
  final int id;
  final String name;

  RoleModel({
    required this.id,
    required this.name,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      // Tangani baik 'id' maupun 'role_id', dan kembali ke nilai 0 jika tidak ada yang disediakan oleh WebSocket
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