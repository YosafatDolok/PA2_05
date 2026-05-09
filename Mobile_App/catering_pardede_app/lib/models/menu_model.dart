import 'category_model.dart';

class MenuModel {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final bool? available;
  final CategoryModel? category;

  MenuModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.available,
    this.category,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['menu_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      available: json['available'] == 1 || json['available'] == true,
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': id,
      'name': name,
      'description': description,
      'image': image,
      'available': available,
      'category': category?.toJson(),
    };
  }
}