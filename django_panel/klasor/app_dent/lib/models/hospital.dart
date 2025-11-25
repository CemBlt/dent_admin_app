class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String email;
  final String description;
  final String? image;
  final List<String>? gallery; // Maksimum 5 fotoğraf
  final List<String> services;
  final Map<String, dynamic> workingHours;
  final String createdAt;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    required this.description,
    this.image,
    this.gallery,
    required this.services,
    required this.workingHours,
    required this.createdAt,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      email: json['email'] as String,
      description: json['description'] as String,
      image: json['image'] as String?,
      gallery: json['gallery'] != null
          ? List<String>.from(json['gallery'] as List)
          : null,
      services: List<String>.from(json['services'] as List),
      workingHours: json['workingHours'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'description': description,
      'image': image,
      'gallery': gallery,
      'services': services,
      'workingHours': workingHours,
      'createdAt': createdAt,
    };
  }
}


