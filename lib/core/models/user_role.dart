enum UserRole {
  admin('admin'),
  moderator('moderator'),
  user('user'),
  anonymous('anonymous');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }

  bool get canModerate => this == UserRole.admin || this == UserRole.moderator;
  bool get isAdmin => this == UserRole.admin;
  bool get isAnonymous => this == UserRole.anonymous;
  bool get isRegistered => this == UserRole.user || canModerate;
}
