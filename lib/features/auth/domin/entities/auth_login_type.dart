enum AuthLoginType { email, phone }

extension AuthLoginTypeX on AuthLoginType {
  String get apiValue => this == AuthLoginType.phone ? 'phone' : 'email';

  bool get isPhone => this == AuthLoginType.phone;
}
