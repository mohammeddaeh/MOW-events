import 'dart:math' show max;

import 'package:mow_events/features/auth/domin/entities/user_entity.dart';

enum MemberSearchMode {
  empty,

  emailAddress,

  phoneDigits,

  mixedLocalEmail,

  textNameOrEmail,
}

class MemberSearchHelper {
  const MemberSearchHelper._();

  static MemberSearchMode classify(String rawQuery) {
    final query = _normalizeText(rawQuery);
    if (query.isEmpty) return MemberSearchMode.empty;
    if (query.contains('@')) return MemberSearchMode.emailAddress;
    if (_isPhoneOnlyQuery(rawQuery)) return MemberSearchMode.phoneDigits;
    final queryDigits = _normalizedDigits(rawQuery);
    if (queryDigits.isNotEmpty) return MemberSearchMode.mixedLocalEmail;
    return MemberSearchMode.textNameOrEmail;
  }

  static bool matches(UserEntity user, String rawQuery) {
    final query = _normalizeText(rawQuery);
    if (query.isEmpty) return true;

    final queryDigits = _normalizedDigits(rawQuery);
    final fullName = _normalizeText(user.fullName);
    final firstName = _normalizeText(user.firstName);
    final lastName = _normalizeText(user.lastName);
    final mergedName = _normalizeText('${user.firstName}${user.lastName}');
    final email = _normalizeText(user.email ?? '');
    final phoneDigits = _normalizedDigits(user.phone ?? '');

    if (query.contains('@')) {
      return email.contains(query);
    }

    if (_isPhoneOnlyQuery(rawQuery)) {
      return queryDigits.isNotEmpty && phoneDigits.contains(queryDigits);
    }

    if (queryDigits.isNotEmpty) {
      return email.isNotEmpty && email.contains(query);
    }

    final nameMatches = _nameMatches(
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      mergedName: mergedName,
      query: query,
    );
    final emailMatches = email.contains(query);
    return nameMatches || emailMatches;
  }

  /// درجة أعلى = تطابق أوضح (للترتيب فقط؛ المستخدمون غير المطابقين يُستبعدون قبل ذلك).
  static int matchScore(UserEntity user, String rawQuery) {
    if (!matches(user, rawQuery)) return -1;
    final query = _normalizeText(rawQuery);
    if (query.isEmpty) return 0;

    if (query.contains('@')) {
      return _scoreEmailField(user, query);
    }
    if (_isPhoneOnlyQuery(rawQuery)) {
      return _scorePhoneField(user, rawQuery);
    }
    final queryDigits = _normalizedDigits(rawQuery);
    if (queryDigits.isNotEmpty) {
      return _scoreEmailField(user, query);
    }
    return _scoreTextFields(user, query);
  }

  static int compareUsersBySearchRelevance(
    UserEntity a,
    UserEntity b,
    String rawQuery,
  ) {
    final sa = matchScore(a, rawQuery);
    final sb = matchScore(b, rawQuery);
    if (sa != sb) return sb.compareTo(sa);
    final ma = a.isManager == true || a.department?.isManager == true;
    final mb = b.isManager == true || b.department?.isManager == true;
    if (ma != mb) return ma ? -1 : 1;
    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  }

  static int _scoreEmailField(UserEntity user, String query) {
    final e = _normalizeText(user.email ?? '');
    if (e.isEmpty || !e.contains(query)) return 1;
    final i = e.indexOf(query);
    var s = 5000 + query.length * 10;
    s -= i * 20;
    if (i == 0) s += 2000;
    if (e == query) s += 3000;
    return s;
  }

  static int _scorePhoneField(UserEntity user, String rawQuery) {
    final qd = _normalizedDigits(rawQuery);
    final pd = _normalizedDigits(user.phone ?? '');
    if (qd.isEmpty || !pd.contains(qd)) return 1;
    final i = pd.indexOf(qd);
    var s = 6000 + qd.length * 15;
    s -= i * 10;
    if (pd.endsWith(qd)) s += 2500;
    if (pd.startsWith(qd)) s += 1500;
    if (pd == qd) s += 4000;
    return s;
  }

  static int _scoreTextFields(UserEntity user, String query) {
    var best = 0;
    final fullName = _normalizeText(user.fullName);
    final firstName = _normalizeText(user.firstName);
    final lastName = _normalizeText(user.lastName);
    final mergedName = _normalizeText('${user.firstName}${user.lastName}');
    final email = _normalizeText(user.email ?? '');

    int scoreNameField(String field) {
      if (field.isEmpty) return 0;
      if (field.startsWith(query)) return 8500;
      var local = 0;
      for (final w in field.split(RegExp(r'\s+'))) {
        if (w.isEmpty) continue;
        if (w.startsWith(query)) {
          local = max(local, 8200);
        } else if (w.contains(query)) {
          final idx = w.indexOf(query);
          local = max(local, 6500 - idx * 5);
        }
      }
      if (local > 0) return local;
      if (field.contains(query)) {
        return 5000 - field.indexOf(query) * 10;
      }
      return 0;
    }

    if (query.length < 3) {
      best = max(best, scoreNameField(fullName));
      best = max(best, scoreNameField(firstName));
      best = max(best, scoreNameField(lastName));
      if (mergedName.startsWith(query)) best = max(best, 8400);
    } else {
      if (fullName.contains(query)) {
        best = max(best, 8000 - fullName.indexOf(query));
      }
      if (firstName.contains(query)) {
        best = max(best, 7800 - firstName.indexOf(query));
      }
      if (lastName.contains(query)) {
        best = max(best, 7800 - lastName.indexOf(query));
      }
      if (mergedName.contains(query)) {
        best = max(best, 7600 - mergedName.indexOf(query));
      }
    }

    if (email.contains(query)) {
      final ei = email.indexOf(query);
      final es = 6000 - ei * 10 + (ei == 0 ? 500 : 0);
      best = max(best, es);
    }

    return best > 0 ? best : 1;
  }

  /// نص الهاتف بعد إزالة الفواصل يجب أن يكون أرقاماً فقط ويطابق الرقم المستخرج.
  static bool _isPhoneOnlyQuery(String rawQuery) {
    final mapped = _mapArabicDigitsToAscii(rawQuery);
    final literal = mapped.replaceAll(RegExp(r'[\s+\-().]'), '');
    if (literal.isEmpty) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(literal)) return false;
    return literal == _normalizedDigits(rawQuery);
  }

  static bool _nameMatches({
    required String fullName,
    required String firstName,
    required String lastName,
    required String mergedName,
    required String query,
  }) {
    if (query.length < 3) {
      return _namePrefixMatch(fullName, query) ||
          _namePrefixMatch(firstName, query) ||
          _namePrefixMatch(lastName, query) ||
          mergedName.startsWith(query);
    }
    return fullName.contains(query) ||
        firstName.contains(query) ||
        lastName.contains(query) ||
        mergedName.contains(query);
  }

  static bool _namePrefixMatch(String field, String query) {
    if (field.isEmpty || query.isEmpty) return false;
    if (field.startsWith(query)) return true;
    for (final word in field.split(RegExp(r'\s+'))) {
      if (word.isNotEmpty && word.startsWith(query)) return true;
    }
    return false;
  }

  static String normalizeQuery(String value) => _normalizeText(value);

  static String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _normalizedDigits(String value) {
    final mapped = _mapArabicDigitsToAscii(value);
    return mapped.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _mapArabicDigitsToAscii(String input) {
    const pairs = [
      ('٠', '0'),
      ('١', '1'),
      ('٢', '2'),
      ('٣', '3'),
      ('٤', '4'),
      ('٥', '5'),
      ('٦', '6'),
      ('٧', '7'),
      ('٨', '8'),
      ('٩', '9'),
    ];
    var s = input;
    for (final p in pairs) {
      s = s.replaceAll(p.$1, p.$2);
    }
    return s;
  }
}
