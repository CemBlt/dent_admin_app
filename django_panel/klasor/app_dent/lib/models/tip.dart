class Tip {
  final String id;
  final String title;
  final String content;
  final String? image;
  final String createdAt;

  Tip({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.createdAt,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': image,
      'createdAt': createdAt,
    };
  }
}


