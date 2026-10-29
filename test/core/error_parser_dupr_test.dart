import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badRequest(Map<String, dynamic> body) => DioException(
  requestOptions: RequestOptions(path: '/tournaments/t1/register'),
  response: Response(
    requestOptions: RequestOptions(path: '/tournaments/t1/register'),
    statusCode: 400,
    data: body,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  group('DUPR_LIMIT_VIOLATION', () {
    // Backend messages name the allowed range; each must come back verbatim.
    const messages = [
      'Điểm DUPR của bạn (3.62) cao hơn mốc tối đa 3.5 của nội dung này.',
      'Điểm DUPR của bạn (2.5) thấp hơn mốc tối thiểu 3.0 của nội dung này.',
      'Bạn chưa khai điểm DUPR cho nội dung này (yêu cầu 3.0 – 3.5).',
    ];

    for (final message in messages) {
      test('returns the backend message: $message', () {
        final error = _badRequest({
          'statusCode': 400,
          'code': 'DUPR_LIMIT_VIOLATION',
          'message': message,
          'details': {
            'reason': 'ABOVE_MAX',
            'minDupr': 3.0,
            'maxDupr': 3.5,
            'value': 3.62,
          },
        });

        expect(ErrorParser.parse(error, 'fallback', l10n), message);
      });
    }
  });

  group('other errors are unchanged', () {
    test('known message still translated', () {
      final error = _badRequest({'message': 'Email already exists'});
      expect(
        ErrorParser.parse(error, 'fallback', l10n),
        l10n.errorParserEmailRegistered,
      );
    });

    test('400 without a message falls back to the generic bad request', () {
      final error = _badRequest({'statusCode': 400});
      expect(
        ErrorParser.parse(error, 'fallback', l10n),
        l10n.errorParserBadRequest,
      );
    });
  });
}
