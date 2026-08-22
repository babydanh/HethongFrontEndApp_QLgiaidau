import 'dart:ui';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

class ErrorParser {
  /// Converts DioException and other errors into user-friendly localized text.
  static String parse(
    dynamic error, [
    String fallback = '',
    AppLocalizations? l10n,
  ]) {
    final strings =
        l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final localizedFallback = fallback.isEmpty
        ? strings.errorParserFallback
        : fallback;

    if (error is! DioException) {
      if (error is Exception) {
        final raw = error.toString();
        final lower = raw.toLowerCase();
        if (lower.contains('canceled') ||
            lower.contains('cancelled') ||
            lower.contains('user_cancelled') ||
            lower.contains('sign_in_canceled')) {
          return strings.errorParserLoginCancelled;
        }
        if (lower.contains('sign_in_failed') ||
            lower.contains('apiexception: 10') ||
            lower.contains('apiexception 10')) {
          return strings.errorParserGoogleUnavailable;
        }
        if (lower.contains('google') &&
            (lower.contains('sign in') ||
                lower.contains('signin') ||
                lower.contains('platformexception'))) {
          return strings.errorParserGoogleSignInFailed;
        }
        if (lower.contains('apple') &&
            (lower.contains('authorization') ||
                lower.contains('credential') ||
                lower.contains('platformexception'))) {
          return strings.errorParserAppleSignInFailed;
        }
        if (lower.contains('divisionid must be a uuid') ||
            lower.contains('division id must be a uuid')) {
          return strings.errorParserInvalidDivision;
        }
        if (lower.contains('no space left on device')) {
          return strings.errorParserNoDeviceSpace;
        }
        return localizedFallback;
      }
      return localizedFallback;
    }

    final e = error;

    if (e.response?.data != null) {
      final responseData = e.response!.data;
      if (responseData is Map<String, dynamic>) {
        final rawMessage = responseData['message'];
        String? msg;
        if (rawMessage is List && rawMessage.isNotEmpty) {
          msg = rawMessage.first.toString();
        } else if (rawMessage is String) {
          msg = rawMessage;
        }

        if (msg != null) {
          final lower = msg.toLowerCase();
          if (lower.contains('divisionid must be a uuid') ||
              lower.contains('division id must be a uuid')) {
            return strings.errorParserInvalidDivision;
          }
          if (lower.contains('payment link') &&
              (lower.contains('expired') || lower.contains('expire'))) {
            return strings.errorParserPaymentLinkExpired;
          }
          if (lower.contains('already paid') ||
              lower.contains('payment already')) {
            return strings.errorParserPaymentAlreadyProcessed;
          }
          if (lower.contains('registration is closed') ||
              lower.contains('chưa hoặc đã đóng')) {
            return strings.errorParserRegistrationClosed;
          }
          if (lower.contains('registration period has not started') ||
              lower.contains('chưa bắt đầu')) {
            return strings.errorParserRegistrationNotStarted;
          }
          if (lower.contains('registration period has ended') ||
              lower.contains('đã kết thúc')) {
            return strings.errorParserRegistrationEnded;
          }
          if (lower.contains('tournament is full') ||
              lower.contains('đã đầy') ||
              lower.contains('đủ số lượng')) {
            return strings.errorParserTournamentFull;
          }
          if (lower.contains('already registered') ||
              lower.contains('đã đăng ký')) {
            return strings.errorParserAlreadyRegistered;
          }
          if (lower.contains('tournament not found') ||
              lower.contains('không tồn tại')) {
            return strings.errorParserTournamentNotFound;
          }
          if (lower.contains('invalid invite code') ||
              lower.contains('mã mời')) {
            return strings.errorParserInvalidInviteCode;
          }
          if (lower.contains("cannot modify field 'tournamentconfig'") ||
              lower.contains('cannot modify tournamentconfig')) {
            return strings.errorParserTournamentConfigLocked;
          }
          if (lower.contains('must be a uuid')) {
            return strings.errorParserInvalidSelection;
          }

          final translated = <String, String>{
            'Email already exists': strings.errorParserEmailRegistered,
            'email should not be empty': strings.errorParserEmailRequired,
            'email must be an email': strings.errorParserEmailInvalid,
            'password must be longer than or equal to 6 characters':
                strings.errorParserPasswordMin,
            'password should not be empty': strings.errorParserPasswordRequired,
            'fullName should not be empty': strings.errorParserFullNameRequired,
            'Invalid credentials': strings.errorParserInvalidCredentialsMessage,
            'Tournament registration is closed':
                strings.errorParserRegistrationClosed,
            'Tài khoản này được đăng ký qua Google. Vui lòng đăng nhập bằng Google.':
                strings.errorParserGoogleAccount,
          }[msg];
          if (translated != null) return translated;
          return msg;
        }
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return strings.errorParserConnectionTimeout;
      case DioExceptionType.connectionError:
        return strings.errorParserConnectionFailed;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 400) return strings.errorParserBadRequest;
        if (code == 401) return strings.errorParserInvalidCredentials;
        if (code == 403) return strings.errorParserForbidden;
        if (code == 404) return strings.errorParserNotFound;
        if (code != null && code >= 500) {
          return strings.errorParserServerError(code);
        }
        return strings.errorParserResponseError(code ?? 0);
      case DioExceptionType.cancel:
        return strings.errorParserRequestCancelled;
      case DioExceptionType.unknown:
      default:
        final errMsg = e.message ?? '';
        if (errMsg.contains('XMLHttpRequest') ||
            errMsg.contains('onError') ||
            errMsg.contains('connection')) {
          return strings.errorParserBrowserConnectionFailed;
        }
        return localizedFallback;
    }
  }
}
