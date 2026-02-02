import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/domin/entities/user_entity.dart';

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phone;
  final String? image;
  final String? address;
  final bool isActive;
  final bool isAdmin;
  final Department? department;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phone,
    this.image,
    this.address,
    required this.isActive,
    required this.isAdmin,
    this.department,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? 0,
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    fullName: json['full_name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone']?.toString() ?? '',
    image: json['image'],
    address: (json['address'] != null && json['address'] != 'null')
        ? json['address']
        : null,
    isActive: (json['is_active'] ?? 0) == 1,
    isAdmin: json['is_admin'] == true,
    department: json['department'] != null
        ? Department.fromJson(json['department'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'image': image,
    'address': address,
    'is_active': isActive ? 1 : 0,
    'is_admin': isAdmin,
    'department': department?.toJson(),
  };

  UserEntity toEntity() => UserEntity(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    email: email,
    phone: phone,
    image: image,
    address: address,
    isActive: isActive,
    isAdmin: isAdmin,
    department: department,
  );
}

class UserListItem {
  final int id;
  final String firstName;
  final String lastName;
  final Department? department;

  UserListItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.department,
  });

  factory UserListItem.fromJson(Map<String, dynamic> json) => UserListItem(
    id: json['id'],
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    department: json['department'] != null
        ? Department.fromJson(json['department'])
        : null,
  );

  String get fullName => "$firstName $lastName";

  UserEntity toEntity() => UserEntity(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    email: null,
    phone: null,
    image: null,
    address: null,
    isActive: true,
    isAdmin: false,
    department: department,
  );
}
