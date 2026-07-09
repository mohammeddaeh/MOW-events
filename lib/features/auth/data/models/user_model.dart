import 'package:mow_events/features/auth/data/models/department.dart';
import 'package:mow_events/features/auth/data/models/user_registration_data.dart';
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
  final UserRegistrationData registrationData;

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
    this.registrationData = const UserRegistrationData(),
  });

  /// حساب بانتظار موافقة الإدارة (من بيانات التسجيل فقط — وليس إيقاف التفعيل من الإدارة).
  bool get requiresRegistrationApproval => registrationData.requiresApproval;

  /// حساب غير مفعّل لكنه ليس في طابور التسجيل (مثل إلغاء التفعيل من الداشبورد).
  bool get isDeactivatedAccount =>
      !isActive && !isAdmin && !registrationData.requiresApproval;

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
      isActive: _readBool(json['is_active']),
      isAdmin: _readBool(json['is_admin']),
      department: department,
      isManager: isManagerRoot || isManagerDept,
      registrationData: UserRegistrationData.resolveFromUserJson(json),
    );
  }

  /// [clearImage] = true يضع image إلى null (لحذف الصورة محلياً بعد النجاح)
  UserModel copyWith({
    String? image,
    bool clearImage = false,
    UserRegistrationData? registrationData,
  }) => UserModel(
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
    registrationData: registrationData ?? this.registrationData,
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
    if (registrationData.registerStatus != null ||
        registrationData.registerDescriptionStatus != null)
      'data_registration_user': registrationData.toJson(),
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

  static bool _readBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return defaultValue;

    if (['1', 'true', 'yes', 'on', 'active'].contains(normalized)) {
      return true;
    }

    if (['0', 'false', 'no', 'off', 'inactive'].contains(normalized)) {
      return false;
    }

    return defaultValue;
  }
}

class UserListItem {
  final int id;
  final String firstName;
  final String lastName;
  final String? fullNameOverride;
  final String? email;
  final String? phone;
  final String? image;
  final String? address;
  final bool isActive;
  final bool isAdmin;
  final Department? department;
  final bool isManager;

  UserListItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fullNameOverride,
    this.email,
    this.phone,
    this.image,
    this.address,
    this.isActive = true,
    this.isAdmin = false,
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
      fullNameOverride:
          (json['full_name']?.toString().trim().isNotEmpty ?? false)
          ? json['full_name'].toString().trim()
          : null,
      email: (json['email']?.toString().trim().isNotEmpty ?? false)
          ? json['email'].toString().trim()
          : null,
      phone: (json['phone']?.toString().trim().isNotEmpty ?? false)
          ? json['phone'].toString().trim()
          : null,
      image:
          (json['image'] != null && json['image'].toString().trim().isNotEmpty)
          ? json['image'].toString().trim()
          : null,
      address:
          (json['address'] != null &&
              json['address'].toString().trim().isNotEmpty &&
              json['address'].toString().trim().toLowerCase() != 'null')
          ? json['address'].toString().trim()
          : null,
      isActive: UserModel._readBool(json['is_active']),
      isAdmin: UserModel._readBool(json['is_admin']),
      department: department,
      isManager: isManagerRoot || isManagerDept,
    );
  }

  String get fullName {
    if (fullNameOverride?.trim().isNotEmpty == true) {
      return fullNameOverride!.trim();
    }
    return "$firstName $lastName".trim();
  }

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
