class RegistrationSubmissionSnapshot {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int departmentId;
  final String departmentName;
  final bool isManager;

  const RegistrationSubmissionSnapshot({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.departmentId,
    required this.departmentName,
    required this.isManager,
  });

  factory RegistrationSubmissionSnapshot.fromJson(Map<String, dynamic> json) {
    return RegistrationSubmissionSnapshot(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      departmentId: int.tryParse(json['department_id']?.toString() ?? '') ?? 0,
      departmentName: json['department_name']?.toString() ?? '',
      isManager: json['is_manager'] == true || json['is_manager'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'department_id': departmentId,
    'department_name': departmentName,
    'is_manager': isManager ? 1 : 0,
  };
}
