import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:mow_events/core/utils/constants/app_config.dart';
import 'package:mow_events/core/utils/error/api_exceptions.dart';
import 'package:mow_events/core/utils/error/error_handler.dart';
import 'package:mow_events/core/utils/error/network_exceptions.dart';
import 'package:mow_events/core/utils/error/validation_exception.dart';
import 'package:mow_events/core/app_router/app_router.dart';
import 'package:mow_events/core/shared/snack_bar/app_snack_bars.dart';
import 'package:mow_events/core/utils/network/network_manager.dart';
import 'package:mow_events/core/utils/translation/app_texts.dart';
import 'package:mow_events/features/auth/presentation/controller/auth_controller.dart';
import 'package:mow_events/features/auth/services/auth_service.dart';

typedef Json = Map<String, dynamic>;

class HttpHelper {
  static const String _baseUrl = AppConfig.baseUrl;

  static Map<String, String> getHeaders({bool withAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth && AuthService.token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${AuthService.token}';
    }

    return headers;
  }

  static Future<Json> get(
    String endpoint, {
    bool showLoader = true,
    bool withAuth = true,
  }) async {
    return _sendRequest(() async {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/$endpoint'),
            headers: getHeaders(withAuth: withAuth),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(res);
    }, withAuth: withAuth);
  }

  static Future<Json> post(
    String endpoint,
    dynamic data, {
    bool showLoader = true,
    bool withAuth = true,
  }) async {
    return _sendRequest(() async {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/$endpoint'),
            headers: getHeaders(withAuth: withAuth),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(res);
    }, withAuth: withAuth);
  }

  static Future<Json> put(
    String endpoint,
    dynamic data, {
    bool showLoader = true,
    bool withAuth = true,
  }) async {
    return _sendRequest(() async {
      final res = await http
          .put(
            Uri.parse('$_baseUrl/$endpoint'),
            headers: getHeaders(withAuth: withAuth),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(res);
    }, withAuth: withAuth);
  }

  static Future<Json> delete(
    String endpoint, {
    bool showLoader = true,
    bool withAuth = true,
  }) async {
    return _sendRequest(() async {
      final res = await http
          .delete(
            Uri.parse('$_baseUrl/$endpoint'),
            headers: getHeaders(withAuth: withAuth),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(res);
    }, withAuth: withAuth);
  }

  static Future<Json> postMultipart(
    String endpoint,
    Map<String, String> fields,
    File? file, {
    bool showLoader = true,
    bool withAuth = true,
    String imageFieldName = 'image',
  }) async {
    return _sendRequest(() async {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final request = http.MultipartRequest(
        'POST',
        uri,
      )..headers.addAll(getHeaders(withAuth: withAuth)..remove('Content-Type'));

      fields.forEach((key, val) => request.fields[key] = val);

      if (file != null) {
        final upload = await http.MultipartFile.fromPath(
          imageFieldName,
          file.path,
        );
        request.files.add(upload);
      }

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      return _handleResponse(res);
    }, withAuth: withAuth);
  }

  static Future<T> _sendRequest<T>(
    Future<T> Function() requestFn, {
    required bool withAuth,
  }) async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      NetworkManager.instance.showSnackBar(
        AppTexts.thePperationCannotBeCompleted,
        AppTexts.checkTheInternetConnection,
        isError: true,
      );
      throw NoInternetException(AppTexts.noInternetConnection);
    }

    try {
      return await requestFn();
    } on TimeoutException {
      NetworkManager.instance.showSnackBar(
        AppTexts.theDeadlineHasEnded,
        AppTexts.failedToConnectToTheServerPleaseTryAgain,
        isError: true,
      );
      throw TimeoutRequestException();
    } on SocketException {
      NetworkManager.instance.showSnackBar(
        AppTexts.connectionFailed,
        AppTexts.cannotReachTheServerCheckYourInternetConnection,
        isError: true,
      );
      throw NoInternetException();
    } on UnauthorizedException catch (e) {
      if (withAuth && AuthService.authenticated) {
        await _handleUnauthorized(e.message);
      }
      rethrow;
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e);
      NetworkManager.instance.showSnackBar(
        AppTexts.warningTitle,
        message,
        isError: true,
      );
      throw ApiException(message);
    }
  }

  static Future<void> _handleUnauthorized(String message) async {
    if (AuthService.isLoggingOut || AuthService.isSessionExpiredHandling)
      return;

    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().logoutDueToUnauthorized(
        message: message,
      );
      return;
    }

    AuthService.isLoggingOut = true;
    AuthService.isSessionExpiredHandling = true;

    try {
      AppSnackBars.hideSnackBar();
      await AuthService.logout();
      Get.offAllNamed(AppRouter.logInScreen);
      await Future.delayed(const Duration(milliseconds: 250));
      final normalizedMessage = message.trim();
      AppSnackBars.warningSnackBar(
        title: AppTexts.warningTitle,
        message:
            normalizedMessage.isEmpty ||
                normalizedMessage.toLowerCase() == 'unauthenticated.'
            ? AppTexts.unauthorized
            : normalizedMessage,
        force: true,
      );
    } finally {
      AuthService.isSessionExpiredHandling = false;
      AuthService.isLoggingOut = false;
    }
  }

  static Json _handleResponse(http.Response res) {
    if (res.statusCode != 200 && res.statusCode != 201) {}

    dynamic decoded;
    try {
      decoded = json.decode(res.body);
    } catch (_) {
      throw ApiException("Invalid JSON format");
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      return decoded;
    }

    final message =
        decoded['error'] ??
        decoded['message'] ??
        AppTexts.anUnknownEerrorHasOccurred;

    switch (res.statusCode) {
      case 400:
        throw ApiException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ApiException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        final fieldErrors = <String, List<String>>{};
        if (decoded["error"] != null &&
            decoded["error"] is Map<String, dynamic>) {
          decoded["error"].forEach((key, value) {
            fieldErrors[key] = List<String>.from(value);
          });
          throw ValidationException(
            decoded["message"] ?? "Validation error",
            fieldErrors,
          );
        }
        throw InvalidDataException(message);

      default:
        if (res.statusCode >= 500) {
          throw ServerException("Server error ${res.statusCode}");
        }
        throw ApiException("Unexpected error: ${res.statusCode}");
    }
  }
}
