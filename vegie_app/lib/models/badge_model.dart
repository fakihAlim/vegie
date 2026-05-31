/// Model for a gamification badge.
///
/// The [isUnlocked] flag is determined client-side by comparing
/// [code] against the user's `unlocked_badge_codes` list returned
/// by the profile endpoint.
class BadgeModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final String lottieFile;
  final bool isUnlocked;
  final int currentProgress;
  final int targetProgress;
  final String progressUnit;

  const BadgeModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.lottieFile,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.targetProgress = 0,
    this.progressUnit = '',
  });

  /// Construct a [BadgeModel] from a server JSON object.
  ///
  /// The server returns `is_unlocked` as a boolean or 1/0 integer.
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      lottieFile: json['lottie_file'] ?? 'assets/lottie/default.json',
      isUnlocked: json['is_unlocked'] == true || json['is_unlocked'] == 1,
      currentProgress: json['current_progress'] != null ? (json['current_progress'] as num).toInt() : 0,
      targetProgress: json['target_progress'] != null ? (json['target_progress'] as num).toInt() : 0,
      progressUnit: json['progress_unit'] ?? '',
    );
  }

  /// Return a copy with [isUnlocked] overridden.
  BadgeModel copyWith({
    bool? isUnlocked,
    int? currentProgress,
    int? targetProgress,
    String? progressUnit,
  }) {
    return BadgeModel(
      id: id,
      code: code,
      name: name,
      description: description,
      lottieFile: lottieFile,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      progressUnit: progressUnit ?? this.progressUnit,
    );
  }

  @override
  String toString() => 'BadgeModel(code: $code, unlocked: $isUnlocked, progress: $currentProgress/$targetProgress)';
}
