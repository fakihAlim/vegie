class Group {
  final int id;
  final String name;
  final String? description;
  final String code;
  final String? photo;
  final String role;
  final String? creatorName;
  final int memberCount;
  final String createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.code,
    this.photo,
    required this.role,
    this.creatorName,
    required this.memberCount,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      code: json['code'] ?? '',
      photo: json['photo'],
      role: json['role'] ?? 'member',
      creatorName: json['creator_name'],
      memberCount: json['member_count'] is int
          ? json['member_count']
          : int.tryParse(json['member_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}
