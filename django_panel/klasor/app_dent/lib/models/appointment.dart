class Appointment {
  final String id;
  final String userId;
  final String hospitalId;
  final String doctorId;
  final String date;
  final String time;
  final String status; // completed, cancelled
  final String service;
  final String notes;
  final String createdAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.hospitalId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    required this.service,
    required this.notes,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      hospitalId: json['hospitalId'] as String,
      doctorId: json['doctorId'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      service: json['service'] as String,
      notes: json['notes'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'hospitalId': hospitalId,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'status': status,
      'service': service,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  Appointment copyWith({
    String? status,
    String? notes,
  }) {
    return Appointment(
      id: id,
      userId: userId,
      hospitalId: hospitalId,
      doctorId: doctorId,
      date: date,
      time: time,
      status: status ?? this.status,
      service: service,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

