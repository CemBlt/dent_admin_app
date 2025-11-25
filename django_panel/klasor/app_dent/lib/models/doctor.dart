class Doctor {
  final String id;
  final String hospitalId;
  final String name;
  final String surname;
  final String specialty;
  final String? image;
  final String bio;
  final Map<String, dynamic> workingHours;
  final String createdAt;

  Doctor({
    required this.id,
    required this.hospitalId,
    required this.name,
    required this.surname,
    this.image,
    required this.specialty,
    required this.bio,
    required this.workingHours,
    required this.createdAt,
  });

  String get fullName => '$name $surname';

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      hospitalId: json['hospitalId'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      specialty: json['specialty'] as String,
      image: json['image'] as String?,
      bio: json['bio'] as String,
      workingHours: json['workingHours'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalId': hospitalId,
      'name': name,
      'surname': surname,
      'specialty': specialty,
      'image': image,
      'bio': bio,
      'workingHours': workingHours,
      'createdAt': createdAt,
    };
  }
}


