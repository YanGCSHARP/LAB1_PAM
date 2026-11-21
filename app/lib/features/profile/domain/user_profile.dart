import 'package:equatable/equatable.dart';

/// The signed-in user, as `GET /auth/me` returns it.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.defaultCurrency,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: '${json['id']}',
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    defaultCurrency: json['defaultCurrency'] as String,
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String email;
  final String displayName;

  /// Currency of the dashboard totals and of budget limits.
  final String defaultCurrency;

  final String? avatarUrl;

  /// Up to two letters for the avatar placeholder: `Ion Rusu` → `IR`.
  String get initials => displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  UserProfile copyWith({
    String? displayName,
    String? defaultCurrency,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'defaultCurrency': defaultCurrency,
    'avatarUrl': avatarUrl,
  };

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    defaultCurrency,
    avatarUrl,
  ];
}
