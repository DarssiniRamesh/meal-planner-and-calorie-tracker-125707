/// Represents an application user.
class AppUser {
  final int id;
  final String email;
  final String? displayName;

  AppUser({required this.id, required this.email, this.displayName});

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'display_name': displayName,
      };

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
    );
  }
}
