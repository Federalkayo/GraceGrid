class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String bio;
  final bool isSignedIn;
  final int unreadMessagesCount;
  final int unreadNotificationsCount;

  const UserProfile({
    required this.id,
    required this.name,
    this.email = '',
    required this.avatarUrl,
    this.bio = '',
    required this.isSignedIn,
    this.unreadMessagesCount = 0,
    this.unreadNotificationsCount = 0,
  });

  factory UserProfile.guest() {
    return const UserProfile(
      id: 'guest',
      name: 'Guest User',
      email: '',
      avatarUrl: '',
      bio: '',
      isSignedIn: false,
      unreadMessagesCount: 0,
      unreadNotificationsCount: 0,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    bool? isSignedIn,
    int? unreadMessagesCount,
    int? unreadNotificationsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }
}

