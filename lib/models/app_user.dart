class AppUser {
  final String uid;
  final String email;
  final String role; // 'admin' or 'employee'
  final bool requiresPasswordChange;
  final String? susuAccountId; // Linked Account Number (Optional)

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.requiresPasswordChange = false,
    this.susuAccountId,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'employee',
      requiresPasswordChange: data['requiresPasswordChange'] ?? false,
      susuAccountId: data['susuAccountId'],
    );
  }
}
