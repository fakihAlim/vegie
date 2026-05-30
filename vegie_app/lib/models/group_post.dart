class GroupPost {
  final int id;
  final String content;
  final String type; // text, achievement, quote
  final String userName;
  final String? userPhoto;
  final String createdAt;

  GroupPost({
    required this.id,
    required this.content,
    required this.type,
    required this.userName,
    this.userPhoto,
    required this.createdAt,
  });

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    return GroupPost(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      userName: json['user_name'] ?? '',
      userPhoto: json['user_photo'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class GroupMember {
  final int id;
  final String name;
  final String? photo;
  final String? bio;
  final String role;
  final String joinedAt;

  GroupMember({
    required this.id,
    required this.name,
    this.photo,
    this.bio,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      photo: json['photo'],
      bio: json['bio'],
      role: json['role'] ?? 'member',
      joinedAt: json['joined_at'] ?? '',
    );
  }
}
