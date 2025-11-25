class Review {
  final String id;
  final String userId;
  final String hospitalId;
  final String? doctorId;
  final String appointmentId;
  final String comment;
  final String createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.hospitalId,
    this.doctorId,
    required this.appointmentId,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      hospitalId: json['hospitalId'] as String,
      doctorId: json['doctorId'] as String?,
      appointmentId: json['appointmentId'] as String,
      comment: json['comment'] as String,
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
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}

