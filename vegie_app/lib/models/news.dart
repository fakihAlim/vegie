class News {
  final int id;
  final String title;
  final String? excerpt;
  final String? content;
  final String? image;
  final DateTime publishedAt;

  News({
    required this.id,
    required this.title,
    this.excerpt,
    this.content,
    this.image,
    required this.publishedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      excerpt: json['excerpt'],
      content: json['content'],
      image: json['image'],
      publishedAt: DateTime.parse(json['published_at']),
    );
  }
}
