class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final int balance;
  final bool isBanned;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'user',
    this.balance = 0,
    this.isBanned = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
      balance: (map['balance'] ?? 0) as int,
      isBanned: (map['isBanned'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'balance': balance,
      'isBanned': isBanned,
    };
  }
}
