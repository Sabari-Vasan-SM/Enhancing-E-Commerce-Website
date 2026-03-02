/// User model matching backend schema.
class UserModel {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String userType;
  final double userTypeConfidence;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.userType,
    this.userTypeConfidence = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      userType: json['user_type'] ?? 'exploration',
      userTypeConfidence: (json['user_type_confidence'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'user_type': userType,
      };

  UserModel copyWith({String? userType, double? userTypeConfidence}) {
    return UserModel(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      userType: userType ?? this.userType,
      userTypeConfidence: userTypeConfidence ?? this.userTypeConfidence,
      isActive: isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}

/// Authentication token response.
class AuthToken {
  final String accessToken;
  final String tokenType;
  final String userType;
  final int userId;

  AuthToken({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.userType,
    required this.userId,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'bearer',
      userType: json['user_type'] ?? 'exploration',
      userId: json['user_id'],
    );
  }
}
