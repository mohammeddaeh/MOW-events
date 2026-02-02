import 'package:mow_events/core/utils/error/app_exciption.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class ApiException extends AppException {
  ApiException(super.message, [super.statusCode]);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String? message])
    : super(message ?? AppTexts.youAreNotAuthorizedToEnter, 401);
}

class NotFoundException extends ApiException {
  NotFoundException([String? message])
    : super(message ?? AppTexts.theResourceDoesNotExist, 404);
}

class InvalidDataException extends AppException {
  InvalidDataException([String? message])
    : super(message ?? AppTexts.invalidData, 422);
}
