class User {
  final String id;
  final String email;
  final String password;
  final String name;
  final String surname;
  final String phone;
  final String? profileImage;
  final String createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.surname,
    required this.phone,
    this.profileImage,
    required this.createdAt,
  });

  String get fullName => '$name $surname';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'surname': surname,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt,
    };
  }
}

