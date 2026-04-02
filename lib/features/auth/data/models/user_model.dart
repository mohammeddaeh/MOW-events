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
  final bool isManager;

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
    this.isManager = false,
  });
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final department = json['department'] != null
        ? Department.fromJson(json['department'])
        : null;
    final isManagerRoot = json['is_manager'] == true || json['is_manager'] == 1;
    final isManagerDept = department?.isManager ?? false;
    return UserModel(
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
      department: department,
      isManager: isManagerRoot || isManagerDept,
    );
  }

  /// [clearImage] = true يضع image إلى null (لحذف الصورة محلياً بعد النجاح)
  UserModel copyWith({String? image, bool clearImage = false}) => UserModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    fullName: fullName,
    email: email,
    phone: phone,
    image: clearImage ? null : (image ?? this.image),
    address: address,
    isActive: isActive,
    isAdmin: isAdmin,
    department: department,
    isManager: isManager,
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
    'is_manager': isManager,
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
    isManager: isManager,
  );
}

class UserListItem {
  final int id;
  final String firstName;
  final String lastName;
  final Department? department;
  final bool isManager;

  UserListItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.department,
    this.isManager = false,
  });

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    final department = json['department'] != null
        ? Department.fromJson(json['department'])
        : null;
    final isManagerRoot = json['is_manager'] == true || json['is_manager'] == 1;
    final isManagerDept = department?.isManager ?? false;
    return UserListItem(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      department: department,
      isManager: isManagerRoot || isManagerDept,
    );
  }

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
    isManager: isManager,
  );
}
