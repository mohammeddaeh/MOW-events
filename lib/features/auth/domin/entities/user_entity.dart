import 'package:mow_events/features/auth/data/models/department.dart';

class UserEntity {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? email;
  final String? phone;
  final String? image;
  final String? address;
  final bool isActive;
  final bool isAdmin;
  final Department? department;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.email,
    this.phone,
    this.image,
    this.address,
    required this.isActive,
    required this.isAdmin,
    this.department,
  });
}
