import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String role;
  final bool isBanned;
  final String? banReason;
  final String? fullName;
  final String? avatar;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? bio;
  final int gamesPlayed;
  final int gamesWon;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isBanned,
    this.banReason,
    this.fullName,
    this.avatar,
    this.dateOfBirth,
    this.phoneNumber,
    this.bio,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      isBanned: json['is_banned'] ?? false,
      banReason: json['ban_reason'],
      fullName: json['full_name'],
      avatar: json['avatar'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      gamesPlayed: json['games_played'] ?? 0,
      gamesWon: json['games_won'] ?? 0,
      rating: json['rating'] ?? 1000,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'is_banned': isBanned,
      'ban_reason': banReason,
      'full_name': fullName,
      'avatar': avatar,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'bio': bio,
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        isBanned,
        banReason,
        fullName,
        avatar,
        dateOfBirth,
        phoneNumber,
        bio,
        gamesPlayed,
        gamesWon,
        rating,
        createdAt,
        updatedAt
      ];

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    bool? isBanned,
    String? banReason,
    String? fullName,
    String? avatar,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? bio,
    int? gamesPlayed,
    int? gamesWon,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
