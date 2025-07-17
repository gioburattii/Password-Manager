class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? notes;
  final String? imageUrl;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.notes,
    this.imageUrl,
  });

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      password: json['password'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'notes': notes,
      'imageUrl': imageUrl,
    };
  }
}


