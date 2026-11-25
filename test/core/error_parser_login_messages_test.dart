import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _reply(int status, String message) => DioException(
  requestOptions: RequestOptions(path: '/auth/mobile/login'),
  response: Response(
    requestOptions: RequestOptions(path: '/auth/mobile/login'),
    statusCode: status,
    data: {'statusCode': status, 'message': message},
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('TC-APP-PHONE-37 Backend login and login-phone texts are localized', () {
    final cases = {
      'Email/số điện thoại hoặc mật khẩu không chính xác.':
          en.errorParserInvalidCredentialsMessage,
      'Nếu tài khoản tồn tại, hướng dẫn đặt lại mật khẩu đã được gửi.':
          en.forgotPassword_genericSentMessage,
      'Mật khẩu hiện tại không chính xác.': en.errorParserCurrentPasswordWrong,
      'Vui lòng nhập mật khẩu hiện tại.': en.errorParserCurrentPasswordRequired,
      'Số điện thoại không hợp lệ': en.errorParserPhoneInvalid,
    };
    for (final entry in cases.entries) {
      expect(ErrorParser.translateMessage(entry.key, en), entry.value);
    }
  });

  test('TC-APP-PHONE-38 a 401 wrong-password reply reads in English', () {
    final error = _reply(
      401,
      'Email/số điện thoại hoặc mật khẩu không chính xác.',
    );

    expect(
      ErrorParser.parse(error, '', en),
      en.errorParserInvalidCredentialsMessage,
    );
  });
}
