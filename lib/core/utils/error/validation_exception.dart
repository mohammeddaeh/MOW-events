import 'package:mow_events/core/utils/error/app_exciption.dart';

class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  ValidationException(super.message, [this.fieldErrors]);

  @override
  String toString() {
    if (fieldErrors == null) return super.toString();
    final errors = fieldErrors!.entries
        .map((e) => '${e.key}: ${e.value.join(', ')}')
        .join('\n');
    return '${super.toString()}\n$errors';
  }
}
