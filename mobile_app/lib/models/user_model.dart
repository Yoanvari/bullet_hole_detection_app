/// Model user yang dikembalikan oleh API auth.
class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String role;

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'shooter',
    );
  }
}
