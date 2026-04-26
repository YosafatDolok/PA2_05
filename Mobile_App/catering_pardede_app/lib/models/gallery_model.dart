class GalleryModel {
  final int id;
  final String image;
  final String? description;

  GalleryModel({
    required this.id,
    required this.image,
    this.description,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    return GalleryModel(
      id: json['id'] ?? json['gallery_id'],
      image: json['image'],
      description: json['description'],
    );
  }
}