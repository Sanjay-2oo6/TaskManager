class Organization {
  final String id;
  final String name;
  final String slug;
  final int memberLimit;
  final int memberCount;
  final String? welcomeMessage;
  final String? themeColor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.memberLimit,
    this.memberCount = 0,
    this.welcomeMessage,
    this.themeColor,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      memberLimit: (json['memberLimit'] as num?)?.toInt() ?? -1,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      welcomeMessage: json['welcomeMessage']?.toString(),
      themeColor: json['themeColor']?.toString(),
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'].toString()) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'].toString()) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'memberLimit': memberLimit,
      'memberCount': memberCount,
      'welcomeMessage': welcomeMessage,
      'themeColor': themeColor,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Check if organization has unlimited members
  bool get hasUnlimitedMembers => memberLimit == -1;

  // Check if organization is at capacity
  bool get isAtCapacity => !hasUnlimitedMembers && memberCount >= memberLimit;

  // Get available member slots
  int get availableMemberSlots {
    if (hasUnlimitedMembers) return -1;
    return memberLimit - memberCount;
  }

  // Copy with method for updates
  Organization copyWith({
    String? id,
    String? name,
    String? slug,
    int? memberLimit,
    int? memberCount,
    String? welcomeMessage,
    String? themeColor,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      memberLimit: memberLimit ?? this.memberLimit,
      memberCount: memberCount ?? this.memberCount,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      themeColor: themeColor ?? this.themeColor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
