/// Gallery image model — from API response
class GalleryImageModel {
  final String id;
  final String imageUrl;
  final String? caption;
  final String createdAt;

  const GalleryImageModel({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.createdAt = '',
  });

  factory GalleryImageModel.fromJson(Map<String, dynamic> json) {
    return GalleryImageModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      caption: json['caption']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
