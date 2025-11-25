class Rating {
  final String id;
  final String userId;
  final String hospitalId;
  final String? doctorId;
  final String appointmentId;
  final int hospitalRating;
  final int? doctorRating;
  final String createdAt;

  Rating({
    required this.id,
    required this.userId,
    required this.hospitalId,
    this.doctorId,
    required this.appointmentId,
    required this.hospitalRating,
    this.doctorRating,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      userId: json['userId'] as String,
      hospitalId: json['hospitalId'] as String,
      doctorId: json['doctorId'] as String?,
      appointmentId: json['appointmentId'] as String,
      hospitalRating: json['hospitalRating'] as int,
      doctorRating: json['doctorRating'] as int?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'hospitalId': hospitalId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'hospitalRating': hospitalRating,
      'doctorRating': doctorRating,
      'createdAt': createdAt,
    };
  }
}

