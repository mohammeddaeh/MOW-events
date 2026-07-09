/// حقول multipart لـ login / register / edit_register (مطابقة Postman).
class AuthApiFields {
  AuthApiFields._();

  static Map<String, String> login({
    required String identifier,
    required String password,
  }) {
    return {
      'email': identifier.trim(),
      'password': password,
    };
  }

  static Map<String, String> registration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int departmentId,
    required bool isManager,
  }) {
    return {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'phone': phone.replaceAll(RegExp(r'\D'), ''),
      'password': password,
      'department_id': departmentId.toString(),
      'is_manager': isManager ? '1' : '0',
    };
  }
}
