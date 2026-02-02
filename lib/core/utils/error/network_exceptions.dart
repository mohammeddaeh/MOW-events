import 'package:mow_events/core/utils/error/app_exciption.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';

class NoInternetException extends AppException {
  NoInternetException([String? message])
    : super(message ?? AppTexts.noInternetConnection);
}

class TimeoutRequestException extends AppException {
  TimeoutRequestException([String? message])
    : super(message ?? AppTexts.theRequestHasTimedOut);
}

class ServerException extends AppException {
  ServerException([String? message])
    : super(message ?? AppTexts.connectionToServerFailed);
}
